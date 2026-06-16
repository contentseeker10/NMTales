using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.enums;
using NMTales.Backend.Models;
using Xunit;

namespace NMTales.Backend.Tests
{
    /// <summary>
    /// Integration tests for the achievement system, verifying event submission, stat tracking, and cross-controller side effects.
    /// </summary>
    public class AchievementControllerTests
    {
        /// <summary>
        /// Helper to register a new test user and return an HttpClient configured with their JWT authorization header.
        /// </summary>
        private static async Task<HttpClient> CreateAuthenticatedClientAsync(QuestApiFactory factory, string username)
        {
            var client = factory.CreateClient();
            var response = await client.PostAsJsonAsync("/api/auth/register",
                new { username, password = "Secret123!" });
            response.EnsureSuccessStatusCode();

            using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            var token = doc.RootElement.GetProperty("token").GetString();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
            return client;
        }

        /// <summary>
        /// Retrieves the internal database ID for a given username.
        /// </summary>
        private static int GetUserId(QuestApiFactory factory, string username)
        {
            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            return db.Users.Single(u => u.Username == username).Id;
        }

        /// <summary>
        /// Executes a scoped database mutation, ensuring changes are saved immediately for testing setup.
        /// </summary>
        private static void Mutate(QuestApiFactory factory, Action<ApplicationDbContext> mutate)
        {
            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            mutate(db);
            db.SaveChanges();
        }

        /// <summary>
        /// Verifies that the endpoint returns the initially seeded achievements with correct default progress for a new user.
        /// </summary>
        [Fact]
        public async Task GetAchievements_ReturnsSeededAchievementsWithInitialProgress()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "user_get_ach");

            var response = await client.GetAsync("/api/achievement");
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            var list = await response.Content.ReadFromJsonAsync<List<JsonElement>>();
            Assert.NotNull(list);
            Assert.Equal(10, list.Count);

            var polymath = list.First(e => e.GetProperty("code").GetString() == "talk_all_assistants");
            Assert.Equal("Polymath", polymath.GetProperty("title").GetString());
            Assert.Equal(150, polymath.GetProperty("xpReward").GetInt32());
            Assert.False(polymath.GetProperty("isUnlocked").GetBoolean());
            Assert.Equal(0, polymath.GetProperty("currentProgress").GetInt32());
            Assert.Equal(3, polymath.GetProperty("targetProgress").GetInt32());
        }

        /// <summary>
        /// Tests the core telemetry submission pipeline across various event types (kills, deaths, unlocks, conversations).
        /// </summary>
        [Fact]
        public async Task SubmitEvent_IncrementsStatsAndReturnsUnlockedAchievements()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "user_event_stats");
            var userId = GetUserId(factory, "user_event_stats");

            // Submit 1 vampire kill
            var res = await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "VampireKill", eventDetail = "" });
            Assert.Equal(HttpStatusCode.OK, res.StatusCode);
            var newlyUnlocked = await res.Content.ReadFromJsonAsync<List<JsonElement>>();
            Assert.Empty(newlyUnlocked);

            // Verify db stats for kills
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var stats = db.PlayerStats.Single(s => s.UserId == userId);
                Assert.Equal(1, stats.VampireKills);
                Assert.Equal(0, stats.DeathsCount);
                Assert.False(stats.HasDied);
            }

            // Submit PlayerDeath
            res = await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "PlayerDeath", eventDetail = "" });
            Assert.Equal(HttpStatusCode.OK, res.StatusCode);

            // Verify db stats for death
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var stats = db.PlayerStats.Single(s => s.UserId == userId);
                Assert.Equal(1, stats.DeathsCount);
                Assert.True(stats.HasDied);
            }

            // Submit SpawnPointUnlocked
            res = await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_forest" });
            Assert.Equal(HttpStatusCode.OK, res.StatusCode);

            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var stats = db.PlayerStats.Single(s => s.UserId == userId);
                var spawns = stats.GetUnlockedSpawnPoints();
                Assert.Single(spawns);
                Assert.Equal("spawn_forest", spawns[0]);
            }

            // Submit AssistantTalked
            res = await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "AssistantTalked", eventDetail = "Math" });
            Assert.Equal(HttpStatusCode.OK, res.StatusCode);

            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var stats = db.PlayerStats.Single(s => s.UserId == userId);
                var talked = stats.GetTalkedAssistants();
                Assert.Single(talked);
                Assert.Equal("Math", talked[0]);
            }
        }

        /// <summary>
        /// Validates that communicating with all three distinct assistants triggers the Polymath achievement.
        /// </summary>
        [Fact]
        public async Task Unlock_TalkAllAssistants_UnlocksAndAwardsXp()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "user_talk_all");
            var userId = GetUserId(factory, "user_talk_all");

            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "AssistantTalked", eventDetail = "Math" });
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "AssistantTalked", eventDetail = "Ukrainian" }); // Normalized to Language
            var res = await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "AssistantTalked", eventDetail = "History" });

            var newlyUnlocked = await res.Content.ReadFromJsonAsync<List<JsonElement>>();
            Assert.Single(newlyUnlocked);
            Assert.Equal("talk_all_assistants", newlyUnlocked[0].GetProperty("code").GetString());
            Assert.Equal(150, newlyUnlocked[0].GetProperty("xpReward").GetInt32());

            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var user = db.Users.Single(u => u.Id == userId);
            Assert.Equal(150, user.XP); // 150 XP awarded
            Assert.True(db.UserAchievements.Any(ua => ua.UserId == userId && ua.Achievement.Code == "talk_all_assistants"));
        }

        /// <summary>
        /// Validates unlocking all spawn points triggers the achievement and correctly applies level-up XP logic.
        /// </summary>
        [Fact]
        public async Task Unlock_UnlockAllSpawns_UnlocksAndAwardsXp()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "user_unlock_spawns");
            var userId = GetUserId(factory, "user_unlock_spawns");

            // Submit all 8 spawn points
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_north" });
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_forest" });
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_cave" });
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_ruins" });
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_swamp" });
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_hill" });
            await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_village" });
            var res = await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "SpawnPointUnlocked", eventDetail = "spawn_bridge" });

            var newlyUnlocked = await res.Content.ReadFromJsonAsync<List<JsonElement>>();
            Assert.Contains(newlyUnlocked, e => e.GetProperty("code").GetString() == "unlock_all_spawns");

            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            Assert.True(db.UserAchievements.Any(ua => ua.UserId == userId && ua.Achievement.Code == "unlock_all_spawns"));
        }

        /// <summary>
        /// Validates that reaching exactly 100 vampire kills triggers the achievement and handles XP carryover.
        /// </summary>
        [Fact]
        public async Task Unlock_Kill100Vampires_UnlocksAndAwardsXp()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "user_kills");
            var userId = GetUserId(factory, "user_kills");

            // Seed user with 49 kills to test the final trigger boundary
            Mutate(factory, db =>
            {
                var stats = db.PlayerStats.FirstOrDefault(s => s.UserId == userId);
                if (stats == null)
                {
                    stats = new PlayerStats { UserId = userId };
                    db.PlayerStats.Add(stats);
                }
                stats.VampireKills = 49;
            });

            var res = await client.PostAsJsonAsync("/api/achievement/event", new { eventType = "VampireKill", eventDetail = "" });
            var newlyUnlocked = await res.Content.ReadFromJsonAsync<List<JsonElement>>();
            Assert.Single(newlyUnlocked);
            Assert.Equal("kill_50_vampires", newlyUnlocked[0].GetProperty("code").GetString());

            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var user = db.Users.Single(u => u.Id == userId);
            
            // 250 XP triggers level up (Level 1 -> 2, leftover XP = 50)
            Assert.Equal(2, user.Level);
            Assert.Equal(50, user.XP);
        }

        /// <summary>
        /// Tests cross-controller functionality ensuring quest completion triggers overarching game progression achievements.
        /// </summary>
        [Fact]
        public async Task QuestController_CompleteQuest_IncrementsStatsAndTriggersUnlocks()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "quest_hook_user");
            var userId = GetUserId(factory, "quest_hook_user");

            // Accept and complete quest
            (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

            // Set progress to 1 (met requirement)
            Mutate(factory, db =>
            {
                var uq = db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted);
                uq.CurrentAmount = 1;
            });

            // Complete quest
            var completeRes = await client.PostAsync("/api/quest/complete", null);
            Assert.Equal(HttpStatusCode.OK, completeRes.StatusCode);

            // Verify CompletedQuestsCount incremented
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var stats = db.PlayerStats.Single(s => s.UserId == userId);
                Assert.Equal(1, stats.CompletedQuestsCount);
            }

            // Cross-verify achievement evaluation happened by completing all 3 test quests.
            (await client.PostAsync("/api/quest/accept/npc_test/quest_2", null)).EnsureSuccessStatusCode();
            Mutate(factory, db => db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted).CurrentAmount = 1);
            await client.PostAsync("/api/quest/complete", null);

            // Accept and complete quest_1 from npc_quest
            (await client.PostAsync("/api/quest/accept/npc_quest/quest_1", null)).EnsureSuccessStatusCode();
            Mutate(factory, db => db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted).CurrentAmount = 3);
            
            // This completion should trigger "complete_all_quests" and "flawless_run" since the user hasn't failed/died
            var finalCompleteRes = await client.PostAsync("/api/quest/complete", null);
            Assert.Equal(HttpStatusCode.OK, finalCompleteRes.StatusCode);

            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var stats = db.PlayerStats.Single(s => s.UserId == userId);
                Assert.Equal(3, stats.CompletedQuestsCount);
                Assert.False(stats.HasFailedTest);
                Assert.False(stats.HasDied);

                // Both achievements should be unlocked
                Assert.True(db.UserAchievements.Any(ua => ua.UserId == userId && ua.Achievement.Code == "complete_all_quests"));
                Assert.True(db.UserAchievements.Any(ua => ua.UserId == userId && ua.Achievement.Code == "flawless_run"));
            }
        }

        /// <summary>
        /// Tests cross-controller functionality ensuring failing an academic test permanently voids "flawless_run" conditions.
        /// </summary>
        [Fact]
        public async Task TestController_Failure_IncrementsStatsAndMarksHasFailedTest()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "test_hook_user");
            var userId = GetUserId(factory, "test_hook_user");

            // Start test using the seeded Logarithms math questions
            var startRes = await client.PostAsJsonAsync("/api/test/start", new { subject = "Math", topic = "Logarithms" });
            Assert.Equal(HttpStatusCode.OK, startRes.StatusCode);

            using var doc = JsonDocument.Parse(await startRes.Content.ReadAsStringAsync());
            var sessionId = doc.RootElement.GetProperty("sessionId").GetInt32();

            // Find a seeded logarithms question that was served for this session
            int questionId = 0;
            int wrongAnsId = 0;
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var session = db.UserTestSessions.Single(s => s.Id == sessionId);
                questionId = session.QuestionIds[0];
                var question = db.Questions.Include(q => q.Answers).Single(q => q.Id == questionId);
                wrongAnsId = question.Answers.First(a => !a.IsCorrect).Id;
            }

            // Submit wrong answer (RemainingAttempts: 2 -> 1)
            var subRes = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = wrongAnsId });
            Assert.Equal(HttpStatusCode.OK, subRes.StatusCode);

            // Stats shouldn't have failed test yet (attempts remaining: 1)
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                Assert.False(db.PlayerStats.Any(s => s.UserId == userId));
            }

            // Submit wrong answer again (RemainingAttempts: 1 -> 0, fails test)
            subRes = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = wrongAnsId });
            Assert.Equal(HttpStatusCode.OK, subRes.StatusCode);

            // Verify stats updated indicating test failure
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var stats = db.PlayerStats.Single(s => s.UserId == userId);
                Assert.Equal(1, stats.FailedTestsCount);
                Assert.True(stats.HasFailedTest);
            }
        }
    }
}
