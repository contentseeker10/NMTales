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

namespace NMTales.Backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize]
    public class AchievementController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IAchievementService _achievementService;
        private readonly IWebHostEnvironment _env;

        private static readonly ConcurrentDictionary<int, SemaphoreSlim> UserGates = new();

        public AchievementController(ApplicationDbContext context, IAchievementService achievementService, IWebHostEnvironment env)
        {
            _context = context;
            _achievementService = achievementService;
            _env = env;
        }

        [HttpGet]
        public async Task<IActionResult> GetAchievements()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var stats = await _context.PlayerStats.FirstOrDefaultAsync(ps => ps.UserId == userId);
            if (stats == null)
            {
                stats = new PlayerStats { UserId = userId };
                _context.PlayerStats.Add(stats);
                await _context.SaveChangesAsync();
            }

            var userAchievements = await _context.UserAchievements
                .Where(ua => ua.UserId == userId)
                .ToDictionaryAsync(ua => ua.AchievementId);

            var achievements = await _context.Achievements.ToListAsync();

            var totalQuests = GetTotalQuestsCount();
            var requiredSpawnPoints = new HashSet<string> { "spawn_north", "spawn_forest" };

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
                            currentProgress = 0;
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

        [HttpPost("event")]
        public async Task<IActionResult> SubmitEvent([FromBody] SubmitTelemetryEventDto dto)
        {
            if (dto == null)
            {
                return BadRequest("Invalid event data.");
            }

            if (!TryGetUserId(out var userId)) return Unauthorized();

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

                // Run evaluation engine
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
                gate.Release();
            }
        }

        private bool TryGetUserId(out int userId)
        {
            var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(userIdValue, out userId);
        }

        private static SemaphoreSlim GateFor(int userId) =>
            UserGates.GetOrAdd(userId, _ => new SemaphoreSlim(1, 1));

        private int GetTotalQuestsCount()
        {
            try
            {
                var questsPath = Path.Combine(_env.ContentRootPath, "Quests");
                if (Directory.Exists(questsPath))
                {
                    return Directory.GetFiles(questsPath, "*.json", SearchOption.AllDirectories).Length;
                }
            }
            catch
            {
                // Fallback
            }
            return 3;
        }
    }
}
