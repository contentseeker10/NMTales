using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Models;
using NMTales.Backend.Services;
using System.Collections.Concurrent;
using System.IO;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.RegularExpressions;
using NMTales.Backend.Services.Auth;
using NMTales.Backend.Services.Player;
using NMTales.Backend.Services.UserQuest;
using NMTales.Backend.Repositories;

namespace NMTales.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class QuestController : ControllerBase
{
    // The closed folder that holds quest configuration files. It lives under the
    // content root (NOT wwwroot) so the raw JSON can never be downloaded directly.
    private const string QuestsRoot = "Quests";

    // Identifiers come straight from the route, so restrict them to a safe charset
    // to prevent path traversal (e.g. "../../appsettings") when building file paths.
    private static readonly Regex SafeIdentifier = new(@"\A[A-Za-z0-9_-]+\z", RegexOptions.Compiled);

    // Serialize accept/complete per user so the check-then-act sequences are atomic and
    // a quest is awarded exactly once. This guards a single server instance (and the
    // in-memory provider, which has no transactions). A multi-instance deployment on a
    // relational provider should additionally use a rowversion/concurrency token and a
    // filtered unique index (UserId WHERE IsCompleted = 0).
    private static readonly ConcurrentDictionary<int, SemaphoreSlim> UserGates = new();

    private readonly IUserQuestService _questService;
    private readonly IPlayerService _userService;
    private readonly IWebHostEnvironment _env;
    private readonly IAchievementService _achievementService;
    private readonly IRepository<PlayerStats> _playerStatsRepository;

    public QuestController(
        IUserQuestService questService,
        IPlayerService userService,
        IWebHostEnvironment env,
        IAchievementService achievementService,
        IRepository<PlayerStats> playerStatsRepository)
    {
        _questService = questService;
        _userService = userService;
        _env = env;
        _achievementService = achievementService;
        _playerStatsRepository = playerStatsRepository;
    }

    /// <summary>
    /// Get the current active quest with the player's live progress merged in.
    /// </summary>
    [HttpGet("active")]
    public async Task<IActionResult> GetActiveQuest()
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var userQuest = await _questService.GetUncompletedQuestAsync(userId);
        
        if (userQuest == null)
        {
            return NoContent(); // No active quest.
        }

        if (!TryGetQuestFilePath(userQuest.NpcId, userQuest.QuestId, out var filePath))
        {
            return NotFound("Quest file not found on server.");
        }

        if (!TryReadQuestConfig(await System.IO.File.ReadAllTextAsync(filePath), out var jsonNode))
        {
            return BadRequest("Corrupt quest file.");
        }

        // Substitute the player's real progress from the DB before returning.
        if (jsonNode["objective"] is JsonObject objectiveNode)
        {
            objectiveNode["current_amount"] = userQuest.CurrentAmount;
        }

        return Ok(jsonNode);
    }

    /// <summary>
    /// Get the list of completed quest IDs for the authenticated player.
    /// </summary>
    [HttpGet("completed")]
    public async Task<IActionResult> GetCompletedQuests()
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        var completedIds = await _questService.GetCompletedQuestsIdsAsync(userId);
        return Ok(completedIds);
    }

    /// <summary>
    /// Accept a new quest offered by an NPC.
    /// </summary>
    [HttpPost("accept/{npcId}/{questId}")]
    public async Task<IActionResult> AcceptQuest(string npcId, string questId)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        // Reject malformed identifiers up front (distinct from a genuinely missing quest).
        if (!IsSafeIdentifier(npcId) || !IsSafeIdentifier(questId))
        {
            return BadRequest("Invalid quest identifier.");
        }

        // The quest must actually exist on the server.
        var filePath = Path.Combine(_env.ContentRootPath, QuestsRoot, npcId, $"{questId}.json");
        if (!System.IO.File.Exists(filePath))
        {
            return NotFound("Requested quest was not found.");
        }

        if (!TryReadQuestConfig(await System.IO.File.ReadAllTextAsync(filePath), out var jsonNode))
        {
            return BadRequest("Corrupt quest file.");
        }

        var gate = GateFor(userId);
        await gate.WaitAsync();
        try
        {
            // Only one active quest at a time.
            var hasActive = await _questService.HasAnyUncompletedQuestAsync(userId);
            if (hasActive)
            {
                return BadRequest("You already have an active quest.");
            }

            var repeatable = false;
            if (jsonNode["repeatable"] is JsonValue repeatableVal && repeatableVal.TryGetValue<bool>(out var rep))
            {
                repeatable = rep;
            }

            if (!repeatable)
            {
                var alreadyCompleted = await _questService.HasCompletedQuestAsync(userId, npcId, questId);
                if (alreadyCompleted)
                {
                    return BadRequest("This quest is not repeatable.");
                }
            }

            await _questService.AddQuestAsync(new UserQuest
            {
                UserId = userId,
                QuestId = questId,
                NpcId = npcId,
                CurrentAmount = 0,
                IsCompleted = false
            });
        }
        finally
        {
            gate.Release();
        }

        return Ok(new { message = "Quest accepted successfully." });
    }

    /// <summary>
    /// Turn in the current active quest and receive the XP reward (server-authoritative).
    /// </summary>
    [HttpPost("complete")]
    public async Task<IActionResult> CompleteQuest()
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var gate = GateFor(userId);
        await gate.WaitAsync();
        try
        {
            var userQuest = await _questService.GetUncompletedQuestAsync(userId);

            if (userQuest == null) return BadRequest("No active quest to complete.");

            if (!TryGetQuestFilePath(userQuest.NpcId, userQuest.QuestId, out var filePath))
            {
                return NotFound("Quest file not found.");
            }

            if (!TryReadQuestConfig(await System.IO.File.ReadAllTextAsync(filePath), out var jsonNode))
            {
                return BadRequest("Corrupt quest file.");
            }

            var requiredAmount = ReadInt(jsonNode["objective"]?["required_amount"], 1);

            // Validate that the objective is actually met before granting any reward.
            if (userQuest.CurrentAmount < requiredAmount)
            {
                return BadRequest("Quest objectives are not completed yet.");
            }

            // Load the rewarded user before mutating state so a missing user can't burn the quest.
            var user = await _userService.GetPlayerAsync(userId);
            if (user == null) return Unauthorized();

            userQuest.IsCompleted = true;

            // Award XP on the server only. The client never decides how much XP it gets.
            // Leveling (next level needs (Level + 1) * 100 XP) lives on the User model so the
            // quest and test reward paths share one implementation.
            var xpReward = ReadInt(jsonNode["rewards"]?["xp"], 0);
            user.AddXp(xpReward);

            // Increment CompletedQuestsCount in player stats
            var statsList = await _playerStatsRepository.GetAllAsync();
            var stats = statsList.FirstOrDefault(ps => ps.UserId == userId);
            if (stats == null)
            {
                stats = new PlayerStats { UserId = userId };
                await _playerStatsRepository.AddAsync(stats);
            }
            stats.CompletedQuestsCount++;
            await _playerStatsRepository.SaveChangesAsync();

            await _questService.SaveChangesAsync();

            // Evaluate and unlock achievements (may award more XP and level up user further)
            await _achievementService.EvaluateAndUnlockAchievementsAsync(userId);

            return Ok(new
            {
                message = "Quest completed successfully.",
                xpEarned = xpReward,
                newLevel = user.Level,
                newXp = user.XP
            });
        }
        finally
        {
            gate.Release();
        }
    }

    /// <summary>
    /// Update the progress of the active quest based on an event.
    /// </summary>
    [HttpPost("progress")]
    public async Task<IActionResult> UpdateProgress([FromBody] QuestProgressRequest request)
    {
        if (request == null)
        {
            return BadRequest("Invalid request body.");
        }

        if (!TryGetUserId(out var userId)) return Unauthorized();

        var gate = GateFor(userId);
        await gate.WaitAsync();
        try
        {
            var userQuest = await _questService.GetUncompletedQuestAsync(userId);

            if (userQuest == null)
            {
                return BadRequest("No active quest.");
            }

            if (!TryGetQuestFilePath(userQuest.NpcId, userQuest.QuestId, out var filePath))
            {
                return NotFound("Quest file not found.");
            }

            if (!TryReadQuestConfig(await System.IO.File.ReadAllTextAsync(filePath), out var jsonNode))
            {
                return BadRequest("Corrupt quest file.");
            }

            if (jsonNode["objective"] is not JsonObject objective)
            {
                return BadRequest("Invalid quest objective.");
            }

            var objectiveType = (string?)objective["type"];
            var objectiveTarget = (string?)objective["target"];
            var requiredAmount = ReadInt(objective["required_amount"], 1);

            var eventType = request.EventType ?? string.Empty;
            var target = request.Target ?? string.Empty;

            if (objectiveType == eventType && objectiveTarget == target)
            {
                if (userQuest.CurrentAmount < requiredAmount)
                {
                    userQuest.CurrentAmount++;
                    await _questService.SaveChangesAsync();
                }
            }

            return Ok(new
            {
                message = "Progress updated successfully.",
                currentAmount = userQuest.CurrentAmount,
                requiredAmount = requiredAmount
            });
        }
        finally
        {
            gate.Release();
        }
    }

    private bool TryGetUserId(out int userId)
    {
        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(userIdValue, out userId);
    }

    private static bool IsSafeIdentifier(string value) => SafeIdentifier.IsMatch(value);

    private static SemaphoreSlim GateFor(int userId) => UserGates.GetOrAdd(userId, _ => new SemaphoreSlim(1, 1));

    /// <summary>
    /// Resolve a quest config path, rejecting unsafe identifiers and confirming the file exists.
    /// </summary>
    private bool TryGetQuestFilePath(string npcId, string questId, out string filePath)
    {
        filePath = string.Empty;

        if (!IsSafeIdentifier(npcId) || !IsSafeIdentifier(questId))
        {
            return false;
        }

        var candidate = Path.Combine(_env.ContentRootPath, QuestsRoot, npcId, $"{questId}.json");
        if (!System.IO.File.Exists(candidate))
        {
            return false;
        }

        filePath = candidate;
        return true;
    }

    /// <summary>
    /// Parse a quest config, treating corrupt JSON as a handled failure rather than a 500.
    /// </summary>
    private static bool TryReadQuestConfig(string jsonString, out JsonNode jsonNode)
    {
        jsonNode = null!;
        try
        {
            var parsed = JsonNode.Parse(jsonString);
            if (parsed == null) return false;
            jsonNode = parsed;
            return true;
        }
        catch (JsonException)
        {
            return false;
        }
    }

    /// <summary>
    /// Read an integer JSON field, falling back when it is absent or not an integer
    /// (a string "100" or 1.5 must not throw).
    /// </summary>
    private static int ReadInt(JsonNode? node, int fallback)
    {
        if (node is JsonValue value && value.TryGetValue<int>(out var result))
        {
            return result;
        }

        return fallback;
    }
}
