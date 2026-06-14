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
    public class PlayerCombatControllerTests
    {
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

        [Fact]
        public async Task Attack_WithoutToken_ReturnsUnauthorized()
        {
            using var factory = new QuestApiFactory();
            var client = factory.CreateClient();

            var response = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        }

        [Fact]
        public async Task Attack_FirstTime_SucceedsAndSetsTimestamp()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "attacker1");

            var response = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);

            using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
            Assert.True(doc.RootElement.GetProperty("success").GetBoolean());

            using var scope = factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var user = db.Users.Single(u => u.Username == "attacker1");
            Assert.NotNull(user.LastAttackTimeUtc);
            Assert.True((DateTime.UtcNow - user.LastAttackTimeUtc.Value).TotalSeconds < 5);
        }

        [Fact]
        public async Task Attack_OnCooldown_ReturnsBadRequest()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "attacker2");

            var response1 = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.OK, response1.StatusCode);

            var response2 = await client.PostAsync("/api/combat/attack", null);
            Assert.Equal(HttpStatusCode.BadRequest, response2.StatusCode);

            using var doc = JsonDocument.Parse(await response2.Content.ReadAsStringAsync());
            Assert.Equal("Attack is on cooldown.", doc.RootElement.GetProperty("error").GetString());
        }

        [Fact]
        public async Task RegisterDamage_ReducesHpAndHandlesDeathAndStats()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "target1");

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

            var response2 = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 60 });
            Assert.Equal(HttpStatusCode.OK, response2.StatusCode);

            using var doc2 = JsonDocument.Parse(await response2.Content.ReadAsStringAsync());
            Assert.Equal(0, doc2.RootElement.GetProperty("currentHp").GetInt32());
            Assert.True(doc2.RootElement.GetProperty("isDead").GetBoolean());

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

        [Fact]
        public async Task Heal_VerifiesDistanceAndRestoresHealth()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "healer1");

            var damageResponse = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 30 });
            Assert.Equal(HttpStatusCode.OK, damageResponse.StatusCode);

            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var user = db.Users.Single(u => u.Username == "healer1");
                user.CurrentPositionX = 1000.0;
                user.CurrentPositionY = 700.0;
                await db.SaveChangesAsync();
            }

            var farResponse = await client.PostAsJsonAsync("/api/combat/heal", new
            {
                plantId = "mushroom_forest_1",
                positionX = 1500.0,
                positionY = 720.0
            });
            Assert.Equal(HttpStatusCode.BadRequest, farResponse.StatusCode);
            var farErr = await farResponse.Content.ReadAsStringAsync();
            Assert.Contains("Too far from the healing item.", farErr);

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

        [Fact]
        public async Task GuardrailFilter_BlocksNonCombatActionsWhenDead()
        {
            using var factory = new QuestApiFactory();
            var client = await CreateAuthenticatedClientAsync(factory, "deadplayer1");

            var damageResponse = await client.PostAsJsonAsync("/api/combat/damage", new { amount = 100 });
            Assert.Equal(HttpStatusCode.OK, damageResponse.StatusCode);

            var moveResponse = await client.PostAsJsonAsync("/api/player/location", new
            {
                currentLocation = "swamp",
                currentPositionX = 200.0,
                currentPositionY = 300.0
            });
            Assert.Equal(HttpStatusCode.BadRequest, moveResponse.StatusCode);

            using var moveDoc = JsonDocument.Parse(await moveResponse.Content.ReadAsStringAsync());
            Assert.Equal("Player is dead. Please respawn.", moveDoc.RootElement.GetProperty("error").GetString());

            var respawnResponse = await client.PostAsync("/api/combat/respawn", null);
            Assert.Equal(HttpStatusCode.OK, respawnResponse.StatusCode);

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
