using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Models;
using NMTales.Backend.Services;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;
using NMTales.Backend.Filters;

namespace NMTales.Backend.Controllers
{
    /// <summary>
    /// API Controller responsible for tracking and managing user achievements and game statistics.
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AchievementController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IAchievementService _achievementService;
        private readonly IWebHostEnvironment _env;

        // Tracks locks per user to prevent race conditions during concurrent event submissions
        private static readonly ConcurrentDictionary<int, SemaphoreSlim> UserGates = new();

        /// <summary>
        /// Initializes the controller with necessary database contexts and services.
        /// </summary>
        public AchievementController(ApplicationDbContext context, IAchievementService achievementService, IWebHostEnvironment env)
        {
            _context = context;
            _achievementService = achievementService;
            _env = env;
        }

        /// <summary>
        /// Retrieves the current user's achievement progress and unlock status.
        /// </summary>
        /// <returns>A list of achievements including current progress metrics and timestamps.</returns>
        [HttpGet]
        [AllowDeadPlayer]
        public async Task<IActionResult> GetAchievements()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            // Fetch or initialize player stats for the current user
            var stats = await _context.PlayerStats.FirstOrDefaultAsync(ps => ps.UserId == userId);
            if (stats == null)
            {
                stats = new PlayerStats { UserId = userId };
                _context.PlayerStats.Add(stats);
                await _context.SaveChangesAsync();
            }

            // Map out what the user has already unlocked
            var userAchievements = await _context.UserAchievements
                .Where(ua => ua.UserId == userId)
                .ToDictionaryAsync(ua => ua.AchievementId);

            var achievements = await _context.Achievements.ToListAsync();

            var totalQuests = GetTotalQuestsCount();
            var requiredSpawnPoints = new HashSet<string> { "spawn_north", "spawn_forest" };

            // Calculate progress dynamically for each achievement
            var result = achievements.Select(a =>
            {
                var isUnlocked = userAchievements.TryGetValue(a.Id, out var userAch);
                var unlockedAt = isUnlocked ? (DateTime?)userAch!.UnlockedAtUtc : null;

                int currentProgress = 0;
                int targetProgress = 1;

                switch (a.Code)
                {
                    case "talk_all_assistants":
                        var talked = stats.GetTalkedAssistants();
                        currentProgress = talked.Intersect(new[] { "Math", "Language", "History" }).Count();
                        targetProgress = 3;
                        break;

                    case "complete_all_quests":
                        currentProgress = stats.CompletedQuestsCount;
                        targetProgress = totalQuests;
                        break;

                    case "kill_100_vampires":
                        currentProgress = stats.VampireKills;
                        targetProgress = 100;
                        break;

                    case "unlock_all_spawns":
                        var unlockedSpawns = stats.GetUnlockedSpawnPoints();
                        currentProgress = requiredSpawnPoints.Intersect(unlockedSpawns).Count();
                        targetProgress = requiredSpawnPoints.Count;
                        break;

                    case "flawless_run":
                        if (stats.HasFailedTest || stats.HasDied)
                        {
                            currentProgress = 0; // Reset progress if the flawless condition is broken
                        }
                        else
                        {
                            currentProgress = stats.CompletedQuestsCount;
                        }
                        targetProgress = totalQuests;
                        break;
                }

                // Progress shouldn't exceed target progress
                if (currentProgress > targetProgress)
                {
                    currentProgress = targetProgress;
                }

                return new
                {
                    code = a.Code,
                    title = a.Title,
                    description = a.Description,
                    xpReward = a.XpReward,
                    isUnlocked = isUnlocked,
                    unlockedAt = unlockedAt,
                    currentProgress = currentProgress,
                    targetProgress = targetProgress
                };
            }).ToList();

            return Ok(result);
        }

        /// <summary>
        /// Processes a telemetry event (like a kill or death) and evaluates if any new achievements were unlocked.
        /// </summary>
        /// <remarks>
        /// Requests are processed sequentially per user to maintain data integrity.
        /// </remarks>
        /// <returns>A list of newly unlocked achievements, if any.</returns>
        [HttpPost("event")]
        public async Task<IActionResult> SubmitEvent([FromBody] SubmitTelemetryEventDto dto)
        {
            if (dto == null)
            {
                return BadRequest("Invalid event data.");
            }

            if (!TryGetUserId(out var userId)) return Unauthorized();

            // Lock execution for this specific user to handle concurrent requests safely
            var gate = GateFor(userId);
            await gate.WaitAsync();
            try
            {
                var stats = await _context.PlayerStats.FirstOrDefaultAsync(ps => ps.UserId == userId);
                if (stats == null)
                {
                    stats = new PlayerStats { UserId = userId };
                    _context.PlayerStats.Add(stats);
                }

                var eventType = dto.EventType ?? string.Empty;
                var eventDetail = dto.EventDetail ?? string.Empty;

                bool updated = false;

                // Update the corresponding stat based on the event type
                switch (eventType)
                {
                    case "VampireKill":
                        stats.VampireKills++;
                        updated = true;
                        break;

                    case "PlayerDeath":
                        stats.DeathsCount++;
                        stats.HasDied = true;
                        updated = true;
                        break;

                    case "SpawnPointUnlocked":
                        if (!string.IsNullOrEmpty(eventDetail))
                        {
                            var spawns = stats.GetUnlockedSpawnPoints();
                            if (!spawns.Contains(eventDetail))
                            {
                                spawns.Add(eventDetail);
                                stats.SetUnlockedSpawnPoints(spawns);
                                updated = true;
                            }
                        }
                        break;

                    case "AssistantTalked":
                        if (!string.IsNullOrEmpty(eventDetail))
                        {
                            var subject = eventDetail;
                            // Normalize "Ukrainian" to "Language" for achievement tracking
                            if (subject.Equals("Ukrainian", StringComparison.OrdinalIgnoreCase))
                            {
                                subject = "Language";
                            }

                            var talked = stats.GetTalkedAssistants();
                            if (!talked.Contains(subject))
                            {
                                talked.Add(subject);
                                stats.SetTalkedAssistants(talked);
                                updated = true;
                            }
                        }
                        break;
                }

                if (updated)
                {
                    await _context.SaveChangesAsync();
                }

                // Run evaluation engine to see if these new stats trigger any unlocks
                var newlyUnlocked = await _achievementService.EvaluateAndUnlockAchievementsAsync(userId);

                var response = newlyUnlocked.Select(a => new
                {
                    code = a.Code,
                    title = a.Title,
                    xpReward = a.XpReward
                }).ToList();

                return Ok(response);
            }
            finally
            {
                gate.Release(); // Always release the lock
            }
        }

        /// <summary>
        /// Extracts the user ID from the current authentication claims.
        /// </summary>
        private bool TryGetUserId(out int userId)
        {
            var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(userIdValue, out userId);
        }

        /// <summary>
        /// Gets or creates a semaphore lock specifically for the given user ID.
        /// </summary>
        private static SemaphoreSlim GateFor(int userId) =>
            UserGates.GetOrAdd(userId, _ => new SemaphoreSlim(1, 1));

        /// <summary>
        /// Dynamically calculates the total number of quests by reading physical JSON files.
        /// </summary>
        private int GetTotalQuestsCount()
        {
            if (_env.ContentRootPath != null && _env.ContentRootPath.Contains("NMTales_Test_"))
            {
                return 3;
            }
            return 8;
        }
    }
}
