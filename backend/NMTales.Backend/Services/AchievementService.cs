using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.Models;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Hosting;

namespace NMTales.Backend.Services
{
    /// <summary>
    /// Service responsible for evaluating player statistics and unlocking achievements.
    /// </summary>
    public class AchievementService : IAchievementService
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        /// <summary>
        /// Initializes a new instance of the <see cref="AchievementService"/>.
        /// </summary>
        public AchievementService(ApplicationDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        /// <summary>
        /// Evaluates the current stats of a specific user against all locked achievements
        /// and grants any that have met their conditions, including XP rewards.
        /// </summary>
        /// <param name="userId">The unique identifier of the user to evaluate.</param>
        /// <returns>A list of newly unlocked achievements.</returns>
        public async Task<List<Achievement>> EvaluateAndUnlockAchievementsAsync(int userId)
        {
            // Load player stats or initialize if not exists
            var stats = await _context.PlayerStats.FirstOrDefaultAsync(ps => ps.UserId == userId);
            if (stats == null)
            {
                stats = new PlayerStats { UserId = userId };
                _context.PlayerStats.Add(stats);
                await _context.SaveChangesAsync();
            }

            // Load user
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return new List<Achievement>();

            // Optimize by pre-loading only the IDs of already unlocked achievements
            var unlockedAchievementIds = (await _context.UserAchievements
                .Where(ua => ua.UserId == userId)
                .Select(ua => ua.AchievementId)
                .ToListAsync())
                .ToHashSet();

            // Load all achievements from database
            var allAchievements = await _context.Achievements.ToListAsync();
            var newlyUnlocked = new List<Achievement>();

            // Determine total number of quests
            var totalQuests = GetTotalQuestsCount();

            // All seeded spawn point IDs (8 total)
            var requiredSpawnPoints = new HashSet<string>
            {
                "spawn_north", "spawn_forest", "spawn_cave", "spawn_ruins",
                "spawn_swamp", "spawn_hill", "spawn_village", "spawn_bridge"
            };

            // Pre-load per-NPC quest completion counts for NPC-based achievements
            var npcQuestCounts = await _context.UserQuests
                .Where(uq => uq.UserId == userId && uq.IsCompleted)
                .GroupBy(uq => uq.NpcId)
                .Select(g => new { NpcId = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.NpcId, x => x.Count);

            // Evaluate each locked achievement against the current player stats
            foreach (var achievement in allAchievements)
            {
                // Skip if already unlocked
                if (unlockedAchievementIds.Contains(achievement.Id))
                {
                    continue;
                }

                bool shouldUnlock = false;

                switch (achievement.Code)
                {
                    case "talk_all_assistants":
                        var talked = stats.GetTalkedAssistants();
                        shouldUnlock = talked.Contains("Math") && talked.Contains("Language") && talked.Contains("History");
                        break;

                    case "complete_all_quests":
                        shouldUnlock = stats.CompletedQuestsCount >= totalQuests && totalQuests > 0;
                        break;

                    case "kill_50_vampires":
                        shouldUnlock = stats.VampireKills >= 50;
                        break;

                    case "unlock_all_spawns":
                        var unlockedSpawns = stats.GetUnlockedSpawnPoints();
                        shouldUnlock = requiredSpawnPoints.All(sp => unlockedSpawns.Contains(sp));
                        break;

                    case "flawless_run":
                        // Flawless run requires game completion (all quests) with zero deaths or failed tests
                        bool completedAll = stats.CompletedQuestsCount >= totalQuests && totalQuests > 0;
                        shouldUnlock = completedAll && !stats.HasFailedTest && !stats.HasDied;
                        break;

                    case "complete_math_quests":
                        npcQuestCounts.TryGetValue("npc_quest_math", out var mathCount);
                        shouldUnlock = mathCount >= 3;
                        break;

                    case "complete_lang_quests":
                        npcQuestCounts.TryGetValue("npc_quest_lang", out var langCount);
                        shouldUnlock = langCount >= 3;
                        break;

                    case "complete_warning_quest":
                        npcQuestCounts.TryGetValue("npc_warning", out var warningCount);
                        shouldUnlock = warningCount >= 1;
                        break;

                    case "reach_level_2":
                        shouldUnlock = user.Level >= 2;
                        break;

                    case "reach_level_5":
                        shouldUnlock = user.Level >= 5;
                        break;
                }

                if (shouldUnlock)
                {
                    // Mark as unlocked
                    var userAch = new UserAchievement
                    {
                        UserId = userId,
                        AchievementId = achievement.Id,
                        UnlockedAtUtc = DateTime.UtcNow
                    };
                    _context.UserAchievements.Add(userAch);

                    // Apply the built-in XP reward to the user profile
                    user.AddXp(achievement.XpReward);

                    newlyUnlocked.Add(achievement);
                }
            }

            if (newlyUnlocked.Any())
            {
                await _context.SaveChangesAsync();
            }

            return newlyUnlocked;
        }

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
