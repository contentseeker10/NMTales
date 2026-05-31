using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using NMTales.Backend.Data;
using Xunit;

namespace NMTales.Backend.Tests;

public class QuestControllerTests
{
    // ----- helpers -------------------------------------------------------------

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

    private static int GetUserId(QuestApiFactory factory, string username)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        return db.Users.Single(u => u.Username == username).Id;
    }

    private static void Mutate(QuestApiFactory factory, Action<ApplicationDbContext> mutate)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        mutate(db);
        db.SaveChanges();
    }

    // ----- authorization / anti-datamining -------------------------------------

    [Fact]
    public async Task ActiveQuest_WithoutToken_ReturnsUnauthorized()
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/quest/active");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task ActiveQuest_WhenNoneAccepted_ReturnsNoContent()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "no_active_user");

        var response = await client.GetAsync("/api/quest/active");

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
    }

    // ----- accept --------------------------------------------------------------

    [Fact]
    public async Task AcceptThenActive_ReturnsQuestConfig()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "accept_user");

        var accept = await client.PostAsync("/api/quest/accept/npc_test/quest_1", null);
        Assert.Equal(HttpStatusCode.OK, accept.StatusCode);

        var active = await client.GetAsync("/api/quest/active");
        Assert.Equal(HttpStatusCode.OK, active.StatusCode);

        using var doc = JsonDocument.Parse(await active.Content.ReadAsStringAsync());
        Assert.Equal("quest_1", doc.RootElement.GetProperty("id").GetString());
        Assert.Equal(0, doc.RootElement.GetProperty("objective").GetProperty("current_amount").GetInt32());
    }

    [Fact]
    public async Task AcceptQuest_WhenAlreadyActive_ReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "double_accept_user");

        (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();
        var second = await client.PostAsync("/api/quest/accept/npc_test/quest_1", null);

        Assert.Equal(HttpStatusCode.BadRequest, second.StatusCode);
    }

    [Fact]
    public async Task AcceptQuest_Unknown_ReturnsNotFound()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "unknown_quest_user");

        var response = await client.PostAsync("/api/quest/accept/npc_test/quest_404", null);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task AcceptQuest_UnsafeIdentifier_IsRejectedWithBadRequestAndPersistsNothing()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "traversal_user");

        // A dotted id would let "{questId}.json" point outside the intended file. The guard
        // must reject it with 400 (BadRequest) — distinct from the 404 a genuinely missing
        // quest returns — so this asserts the guard itself, not an incidental missing file.
        var response = await client.PostAsync("/api/quest/accept/npc_test/quest_1.json", null);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        Assert.False(db.UserQuests.Any());
    }

    // ----- active quest reflects live progress ---------------------------------

    [Fact]
    public async Task ActiveQuest_ReflectsLiveProgressFromDb()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "progress_user");
        (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        var userId = GetUserId(factory, "progress_user");
        Mutate(factory, db =>
            db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted).CurrentAmount = 1);

        var active = await client.GetAsync("/api/quest/active");
        using var doc = JsonDocument.Parse(await active.Content.ReadAsStringAsync());
        Assert.Equal(1, doc.RootElement.GetProperty("objective").GetProperty("current_amount").GetInt32());
    }

    // ----- complete / anti-cheat ----------------------------------------------

    [Fact]
    public async Task CompleteQuest_NoActive_ReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "no_quest_complete");

        var response = await client.PostAsync("/api/quest/complete", null);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CompleteQuest_ObjectivesNotMet_ReturnsBadRequestAndAwardsNoXp()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "incomplete_user");
        (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        var complete = await client.PostAsync("/api/quest/complete", null);
        Assert.Equal(HttpStatusCode.BadRequest, complete.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var user = db.Users.Single(u => u.Username == "incomplete_user");
        Assert.Equal(0, user.XP);
        Assert.Equal(1, user.Level);
        Assert.False(db.UserQuests.Single().IsCompleted);
    }

    [Fact]
    public async Task CompleteQuest_ObjectivesMet_AwardsXpAndMarksCompleted()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "winner");
        (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        var userId = GetUserId(factory, "winner");
        // No progress endpoint exists in the spec, so simulate the objective being met.
        Mutate(factory, db =>
            db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted).CurrentAmount = 1);

        var complete = await client.PostAsync("/api/quest/complete", null);
        Assert.Equal(HttpStatusCode.OK, complete.StatusCode);

        using var doc = JsonDocument.Parse(await complete.Content.ReadAsStringAsync());
        Assert.Equal(100, doc.RootElement.GetProperty("xpEarned").GetInt32());
        Assert.Equal(1, doc.RootElement.GetProperty("newLevel").GetInt32());
        Assert.Equal(100, doc.RootElement.GetProperty("newXp").GetInt32());

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        Assert.True(db.UserQuests.Single().IsCompleted);
    }

    [Fact]
    public async Task CompleteQuest_CrossingThreshold_LevelsUp()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "leveler");
        (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        var userId = GetUserId(factory, "leveler");
        Mutate(factory, db =>
        {
            var quest = db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted);
            quest.CurrentAmount = 1;
            db.Users.Single(u => u.Id == userId).XP = 150; // +100 reward crosses the 200 threshold
        });

        var complete = await client.PostAsync("/api/quest/complete", null);
        using var doc = JsonDocument.Parse(await complete.Content.ReadAsStringAsync());
        Assert.Equal(2, doc.RootElement.GetProperty("newLevel").GetInt32());
        Assert.Equal(50, doc.RootElement.GetProperty("newXp").GetInt32());
    }

    [Fact]
    public async Task CompleteQuest_MultiLevelJump_ConsumesXpAcrossLevels()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "multi_leveler");
        (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        var userId = GetUserId(factory, "multi_leveler");
        Mutate(factory, db =>
        {
            db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted).CurrentAmount = 1;
            // L1 XP=450, +100 reward = 550: cross 200 (->L2,350) then 300 (->L3,50); 50 < 400 stops.
            db.Users.Single(u => u.Id == userId).XP = 450;
        });

        var complete = await client.PostAsync("/api/quest/complete", null);
        using var doc = JsonDocument.Parse(await complete.Content.ReadAsStringAsync());
        Assert.Equal(3, doc.RootElement.GetProperty("newLevel").GetInt32());
        Assert.Equal(50, doc.RootElement.GetProperty("newXp").GetInt32());
    }

    [Fact]
    public async Task CompleteQuest_Replay_IsRejectedAndDoesNotAwardExtraXp()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "replayer");
        (await client.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        var userId = GetUserId(factory, "replayer");
        Mutate(factory, db =>
            db.UserQuests.Single(q => q.UserId == userId && !q.IsCompleted).CurrentAmount = 1);

        (await client.PostAsync("/api/quest/complete", null)).EnsureSuccessStatusCode();
        var replay = await client.PostAsync("/api/quest/complete", null);
        Assert.Equal(HttpStatusCode.BadRequest, replay.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var user = db.Users.Single(u => u.Username == "replayer");
        Assert.Equal(100, user.XP); // reward applied exactly once
        Assert.Equal(1, user.Level);
    }

    // ----- anti-datamining (T1): a player only ever sees their OWN active quest -------

    [Fact]
    public async Task ActiveQuest_DoesNotLeakAnotherUsersQuest()
    {
        using var factory = new QuestApiFactory();
        var owner = await CreateAuthenticatedClientAsync(factory, "owner_a");
        (await owner.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        // A second user on the SAME server, holding no quest, must not see the owner's quest.
        var intruder = await CreateAuthenticatedClientAsync(factory, "intruder_b");
        var intruderActive = await intruder.GetAsync("/api/quest/active");

        Assert.Equal(HttpStatusCode.NoContent, intruderActive.StatusCode);
    }

    [Fact]
    public async Task ActiveQuest_EachUserSeesOnlyTheirOwnProgress()
    {
        using var factory = new QuestApiFactory();
        var clientA = await CreateAuthenticatedClientAsync(factory, "progress_a");
        var clientB = await CreateAuthenticatedClientAsync(factory, "progress_b");
        (await clientA.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();
        (await clientB.PostAsync("/api/quest/accept/npc_test/quest_1", null)).EnsureSuccessStatusCode();

        var userA = GetUserId(factory, "progress_a");
        Mutate(factory, db =>
            db.UserQuests.Single(q => q.UserId == userA && !q.IsCompleted).CurrentAmount = 1);

        using var aDoc = JsonDocument.Parse(await (await clientA.GetAsync("/api/quest/active")).Content.ReadAsStringAsync());
        using var bDoc = JsonDocument.Parse(await (await clientB.GetAsync("/api/quest/active")).Content.ReadAsStringAsync());
        Assert.Equal(1, aDoc.RootElement.GetProperty("objective").GetProperty("current_amount").GetInt32());
        Assert.Equal(0, bDoc.RootElement.GetProperty("objective").GetProperty("current_amount").GetInt32());
    }

    // ----- anti-datamining (T1): raw config files are not served as static content ----

    [Theory]
    [InlineData("/Quests/npc_test/quest_1.json")]
    [InlineData("/quest_1.json")]
    public async Task QuestConfigFiles_AreNotDirectlyDownloadable(string path)
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.GetAsync(path);

        // The closed Quests/ folder must never be reachable as a static file.
        Assert.NotEqual(HttpStatusCode.OK, response.StatusCode);
    }
}
