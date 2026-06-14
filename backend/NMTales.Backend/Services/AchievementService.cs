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
    public class AchievementService : IAchievementService
    {
        private readonly ApplicationDbContext _context;
        private readonly IWebHostEnvironment _env;

        public AchievementService(ApplicationDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

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

            // Load all achievements currently unlocked by the user
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

            // All seeded spawn point IDs
            var requiredSpawnPoints = new HashSet<string> { "spawn_north", "spawn_forest" };

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

                    case "kill_100_vampires":
                        shouldUnlock = stats.VampireKills >= 100;
                        break;

                    case "unlock_all_spawns":
                        var unlockedSpawns = stats.GetUnlockedSpawnPoints();
                        shouldUnlock = requiredSpawnPoints.All(sp => unlockedSpawns.Contains(sp));
                        break;

                    case "flawless_run":
                        bool completedAll = stats.CompletedQuestsCount >= totalQuests && totalQuests > 0;
                        shouldUnlock = completedAll && !stats.HasFailedTest && !stats.HasDied;
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

                    // Add XP reward to the user
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
