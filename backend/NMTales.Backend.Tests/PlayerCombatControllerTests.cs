using System;
using System.Linq;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Models;
using Xunit;

namespace NMTales.Backend.Tests
{
    /// <summary>
    /// Integration tests for the player combat system, covering attacks, damage processing, healing, death states, and action restrictions.
    /// </summary>
    public class PlayerCombatControllerTests
    {
        /// <summary>
        /// Helper method to register a uniquely named user and return an HttpClient configured with their Bearer authentication token.
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
        /// Verifies that unauthenticated requests to the attack endpoint are rejected.
        /// </summary>
        [Fact]
        public async Task Attack_WithoutToken_ReturnsUnauthorized()
        {
            using var factory = new QuestApiFactory();
            var client = factory.CreateClient();

            var response = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        }

        /// <summary>
        /// Verifies that a valid attack registers successfully and updates the player's last attack timestamp.
        /// </summary>
        [Fact]
        public async Task Attack_FirstTime_SucceedsAndSetsTimestamp()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "attacker1");

            var response = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            Assert.True(doc.RootElement.GetProperty("success").GetBoolean());

            // Confirm the database timestamp was updated within a reasonable recent window
            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var user = db.Users.Single(u => u.Username == "attacker1");
            Assert.NotNull(user.LastAttackTimeUtc);
            Assert.True((DateTime.UtcNow - user.LastAttackTimeUtc.Value).TotalSeconds < 5);
        }

        /// <summary>
        /// Verifies that attempting to attack consecutively too quickly triggers the server-side cooldown restriction.
        /// </summary>
        [Fact]
        public async Task Attack_OnCooldown_ReturnsBadRequest()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "attacker2");

            // First attack should succeed
            var response1 = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.OK, response1.StatusCode);

            // Immediate second attack should be blocked by cooldown
            var response2 = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.BadRequest, response2.StatusCode);

            using var doc = JsonDocument.Parse(await response2.Content.ReadAsStringAsync());
            Assert.Equal("Attack is on cooldown.", doc.RootElement.GetProperty("error").GetString());
        }

        /// <summary>
        /// Verifies that incoming damage reduces health, and fatal damage correctly transitions the player to a dead state while updating stats.
        /// </summary>
        [Fact]
        public async Task RegisterDamage_ReducesHpAndHandlesDeathAndStats()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "target1");

            // Apply non-fatal damage
            var response1 = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 30 });
            Assert.Equal(HttpStatusCode.OK, response1.StatusCode);

            using var doc1 = JsonDocument.Parse(await response1.Content.ReadAsStringAsync());
            Assert.Equal(50, doc1.RootElement.GetProperty("currentHp").GetInt32());
            Assert.False(doc1.RootElement.GetProperty("isDead").GetBoolean());

            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var user = db.Users.Single(u => u.Username == "target1");
                Assert.Equal(50, user.CurrentHp);
                Assert.False(user.IsDead);
            }

            // Apply fatal damage
            var response2 = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 60 });
            Assert.Equal(HttpStatusCode.OK, response2.StatusCode);

            using var doc2 = JsonDocument.Parse(await response2.Content.ReadAsStringAsync());
            Assert.Equal(0, doc2.RootElement.GetProperty("currentHp").GetInt32());
            Assert.True(doc2.RootElement.GetProperty("isDead").GetBoolean());

            // Confirm death state and stat tracking persistence
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var user = db.Users.Single(u => u.Username == "target1");
                Assert.Equal(0, user.CurrentHp);
                Assert.True(user.IsDead);

                var stats = db.PlayerStats.Single(ps => ps.UserId == user.Id);
                Assert.Equal(1, stats.DeathsCount);
                Assert.True(stats.HasDied);
            }
        }

        /// <summary>
        /// Verifies that healing items only apply when the player is within the physical distance threshold.
        /// </summary>
        [Fact]
        public async Task Heal_VerifiesDistanceAndRestoresHealth()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "healer1");

            var damageResponse = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 30 });
            Assert.Equal(HttpStatusCode.OK, damageResponse.StatusCode);

            // Force player coordinates in DB to set up the distance test
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var user = db.Users.Single(u => u.Username == "healer1");
                user.CurrentPositionX = 1000.0;
                user.CurrentPositionY = 700.0;
                await db.SaveChangesAsync();
            }

            // Attempt healing from outside the allowed radius
            var farResponse = await client.PostAsJsonAsync("/api/combat/heal", new
            {
                plantId = "mushroom_forest_1",
                positionX = 1500.0,
                positionY = 720.0
            });
            Assert.Equal(HttpStatusCode.BadRequest, farResponse.StatusCode);
            var farErr = await farResponse.Content.ReadAsStringAsync();
            Assert.Contains("Too far from the healing item.", farErr);

            // Attempt healing from within the allowed radius
            var closeResponse = await client.PostAsJsonAsync("/api/combat/heal", new
            {
                plantId = "mushroom_forest_1",
                positionX = 1050.0,
                positionY = 710.0
            });
            Assert.Equal(HttpStatusCode.OK, closeResponse.StatusCode);

            using var closeDoc = JsonDocument.Parse(await closeResponse.Content.ReadAsStringAsync());
            Assert.Equal(60, closeDoc.RootElement.GetProperty("currentHp").GetInt32());

            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var user = db.Users.Single(u => u.Username == "healer1");
                Assert.Equal(60, user.CurrentHp);
            }
        }

        /// <summary>
        /// Verifies that respawning properly resets a dead player's health, status, and coordinates.
        /// </summary>
        [Fact]
        public async Task Respawn_RestoresHpAndClearsDeadState()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "respawner1");

            var damageResponse = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 85 });
            Assert.Equal(HttpStatusCode.OK, damageResponse.StatusCode);

            var respawnResponse = await client.PostAsync("/api/combat/respawn", null);
            Assert.Equal(HttpStatusCode.OK, respawnResponse.StatusCode);

            using var respawnDoc = JsonDocument.Parse(await respawnResponse.Content.ReadAsStringAsync());
            Assert.Equal(20, respawnDoc.RootElement.GetProperty("currentHp").GetInt32());
            Assert.False(respawnDoc.RootElement.GetProperty("isDead").GetBoolean());
            Assert.Equal(0.0, respawnDoc.RootElement.GetProperty("positionX").GetDouble());
            Assert.Equal(0.0, respawnDoc.RootElement.GetProperty("positionY").GetDouble());

            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var user = db.Users.Single(u => u.Username == "respawner1");
            Assert.Equal(20, user.CurrentHp);
            Assert.False(user.IsDead);
            Assert.Equal(0.0, user.CurrentPositionX);
            Assert.Equal(0.0, user.CurrentPositionY);
        }

        /// <summary>
        /// Verifies that the global action filter successfully blocks unauthorized actions (like location updates) while the player is in a dead state.
        /// </summary>
        [Fact]
        public async Task GuardrailFilter_BlocksNonCombatActionsWhenDead()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "deadplayer1");

            // Kill the player
            var damageResponse = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 100 });
            Assert.Equal(HttpStatusCode.OK, damageResponse.StatusCode);

            // Attempt an action not marked with AllowDeadPlayerAttribute
            var moveResponse = await client.PostAsJsonAsync("/api/player/location", new
            {
                currentLocation = "swamp",
                currentPositionX = 200.0,
                currentPositionY = 300.0
            });
            Assert.Equal(HttpStatusCode.BadRequest, moveResponse.StatusCode);

            using var moveDoc = JsonDocument.Parse(await moveResponse.Content.ReadAsStringAsync());
            Assert.Equal("Player is dead. Please respawn.", moveDoc.RootElement.GetProperty("error").GetString());

            // Respawn
            var respawnResponse = await client.PostAsync("/api/combat/respawn", null);
            Assert.Equal(HttpStatusCode.OK, respawnResponse.StatusCode);

            // Confirm action is permitted again once alive
            var moveResponse2 = await client.PostAsJsonAsync("/api/player/location", new
            {
                currentLocation = "swamp",
                currentPositionX = 200.0,
                currentPositionY = 300.0
            });
            Assert.Equal(HttpStatusCode.OK, moveResponse2.StatusCode);
        }
    }
}
