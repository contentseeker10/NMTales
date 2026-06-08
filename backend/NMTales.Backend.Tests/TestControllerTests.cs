using System.Linq;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using NMTales.Backend.Data;
using Xunit;

namespace NMTales.Backend.Tests;

/// <summary>
/// Integration tests for the stateful test system (math altars + Ukrainian scrolls).
/// The suite reads the seeded answer keys straight from the in-memory DB to drive a run,
/// exactly the way a server would validate — the client payloads never expose correctness.
/// </summary>
public class TestControllerTests
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

    private static T Read<T>(QuestApiFactory factory, Func<ApplicationDbContext, T> read)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        return read(db);
    }

    private static int CurrentQuestionId(QuestApiFactory factory, int sessionId) =>
        Read(factory, db =>
        {
            var session = db.UserTestSessions.Single(s => s.Id == sessionId);
            return session.QuestionIds[session.CurrentQuestionIndex];
        });

    private static int CorrectAnswerId(QuestApiFactory factory, int questionId) =>
        Read(factory, db => db.Answers.Single(a => a.QuestionId == questionId && a.IsCorrect).Id);

    private static int WrongAnswerId(QuestApiFactory factory, int questionId) =>
        Read(factory, db => db.Answers.First(a => a.QuestionId == questionId && !a.IsCorrect).Id);

    private static async Task<JsonElement> StartAsync(HttpClient client, string subject, string topic)
    {
        var response = await client.PostAsJsonAsync("/api/test/start", new { subject, topic });
        response.EnsureSuccessStatusCode();
        var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return doc.RootElement.Clone();
    }

    // ----- authorization -------------------------------------------------------

    [Fact]
    public async Task Start_WithoutToken_ReturnsUnauthorized()
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/test/start", new { subject = "Math", topic = "Logarithms" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Submit_WithoutToken_ReturnsUnauthorized()
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/test/submit", new { sessionId = 1, answerId = 1 });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ----- start ---------------------------------------------------------------

    [Fact]
    public async Task StartMath_PicksThreeUniqueQuestions_AndHidesCorrectness()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "math_start");

        var response = await client.PostAsJsonAsync("/api/test/start", new { subject = "Math", topic = "Logarithms" });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadAsStringAsync();

        // The payload must never leak which option is correct.
        Assert.DoesNotContain("isCorrect", json, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("correctSlotIndex", json, StringComparison.OrdinalIgnoreCase);

        using var doc = JsonDocument.Parse(json);
        Assert.Equal(3, doc.RootElement.GetProperty("totalQuestions").GetInt32());
        Assert.Equal(0, doc.RootElement.GetProperty("currentQuestionIndex").GetInt32());
        Assert.True(doc.RootElement.GetProperty("question").GetProperty("answers").GetArrayLength() > 0);

        var sessionId = doc.RootElement.GetProperty("sessionId").GetInt32();
        var ids = Read(factory, db => db.UserTestSessions.Single(s => s.Id == sessionId).QuestionIds);
        Assert.Equal(3, ids.Count);
        Assert.Equal(3, ids.Distinct().Count()); // strictly unique
    }

    [Fact]
    public async Task StartUkrainian_PicksOneScroll_WithDistractors_AndHidesSlots()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "ua_start");

        var response = await client.PostAsJsonAsync("/api/test/start", new { subject = "Ukrainian", topic = "Syntax" });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var json = await response.Content.ReadAsStringAsync();
        Assert.DoesNotContain("correctSlotIndex", json, StringComparison.OrdinalIgnoreCase);

        using var doc = JsonDocument.Parse(json);
        Assert.Equal(1, doc.RootElement.GetProperty("totalQuestions").GetInt32());
        // 2 real slots + 2 distractors were seeded per scroll.
        Assert.Equal(4, doc.RootElement.GetProperty("question").GetProperty("answers").GetArrayLength());
    }

    [Fact]
    public async Task Start_UnknownSubject_ReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "bad_subject");

        var response = await client.PostAsJsonAsync("/api/test/start", new { subject = "Chemistry", topic = "Logarithms" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Start_UnknownTopic_ReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "bad_topic");

        var response = await client.PostAsJsonAsync("/api/test/start", new { subject = "Math", topic = "Nonexistent" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task StartAgain_DropsTheUnfinishedSession()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "restart_user");
        var userId = GetUserId(factory, "restart_user");

        var first = await StartAsync(client, "Math", "Logarithms");
        var firstId = first.GetProperty("sessionId").GetInt32();

        var second = await StartAsync(client, "Math", "Logarithms");
        var secondId = second.GetProperty("sessionId").GetInt32();

        Assert.NotEqual(firstId, secondId);
        // The stale session is gone; exactly one active session remains.
        Assert.False(Read(factory, db => db.UserTestSessions.Any(s => s.Id == firstId)));
        Assert.Equal(1, Read(factory, db => db.UserTestSessions.Count(s => s.UserId == userId && !s.IsCompleted)));
    }

    // ----- submit: math --------------------------------------------------------

    [Fact]
    public async Task SubmitMath_AllCorrect_CompletesAndAwardsXp()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "math_winner");

        var start = await StartAsync(client, "Math", "Logarithms");
        var sessionId = start.GetProperty("sessionId").GetInt32();

        // Answer all three questions correctly.
        for (var step = 0; step < 3; step++)
        {
            var qid = CurrentQuestionId(factory, sessionId);
            var submit = await client.PostAsJsonAsync("/api/test/submit",
                new { sessionId, answerId = CorrectAnswerId(factory, qid) });
            Assert.Equal(HttpStatusCode.OK, submit.StatusCode);

            using var doc = JsonDocument.Parse(await submit.Content.ReadAsStringAsync());
            Assert.True(doc.RootElement.GetProperty("correct").GetBoolean());
            if (step < 2)
            {
                Assert.False(doc.RootElement.GetProperty("completed").GetBoolean());
                Assert.True(doc.RootElement.TryGetProperty("nextQuestion", out _));
            }
            else
            {
                Assert.True(doc.RootElement.GetProperty("completed").GetBoolean());
            }
        }

        var (xp, level, completed) = Read(factory, db =>
        {
            var u = db.Users.Single(x => x.Username == "math_winner");
            var done = db.UserTestSessions.Single(s => s.Id == sessionId).IsCompleted;
            return (u.XP, u.Level, done);
        });
        Assert.Equal(100, xp);
        Assert.Equal(1, level);
        Assert.True(completed);
    }

    [Fact]
    public async Task SubmitMath_CompletingCanLevelUp()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "math_leveler");

        var start = await StartAsync(client, "Math", "Logarithms");
        var sessionId = start.GetProperty("sessionId").GetInt32();

        // 150 + 100 reward crosses the level-2 threshold of 200 -> level 2 with 50 left over.
        Mutate(factory, db => db.Users.Single(u => u.Username == "math_leveler").XP = 150);

        for (var step = 0; step < 3; step++)
        {
            var qid = CurrentQuestionId(factory, sessionId);
            (await client.PostAsJsonAsync("/api/test/submit",
                new { sessionId, answerId = CorrectAnswerId(factory, qid) })).EnsureSuccessStatusCode();
        }

        var (xp, level) = Read(factory, db =>
        {
            var u = db.Users.Single(x => x.Username == "math_leveler");
            return (u.XP, u.Level);
        });
        Assert.Equal(2, level);
        Assert.Equal(50, xp);
    }

    [Fact]
    public async Task SubmitMath_FirstWrong_ReturnsRemainingAttempt_ThenSecondWrong_Fails()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "math_loser");

        var start = await StartAsync(client, "Math", "Logarithms");
        var sessionId = start.GetProperty("sessionId").GetInt32();
        var qid = CurrentQuestionId(factory, sessionId);
        var wrong = WrongAnswerId(factory, qid);

        var first = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = wrong });
        using (var doc = JsonDocument.Parse(await first.Content.ReadAsStringAsync()))
        {
            Assert.False(doc.RootElement.GetProperty("correct").GetBoolean());
            Assert.False(doc.RootElement.GetProperty("failed").GetBoolean());
            Assert.Equal(1, doc.RootElement.GetProperty("remainingAttempts").GetInt32());
        }

        var second = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = wrong });
        using (var doc = JsonDocument.Parse(await second.Content.ReadAsStringAsync()))
        {
            Assert.False(doc.RootElement.GetProperty("correct").GetBoolean());
            Assert.True(doc.RootElement.GetProperty("failed").GetBoolean());
        }

        Assert.True(Read(factory, db => db.UserTestSessions.Single(s => s.Id == sessionId).IsFailed));
        // No XP for a failed run.
        Assert.Equal(0, Read(factory, db => db.Users.Single(u => u.Username == "math_loser").XP));
    }

    [Fact]
    public async Task SubmitMath_ToFailedSession_ReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "failed_session");

        var start = await StartAsync(client, "Math", "Logarithms");
        var sessionId = start.GetProperty("sessionId").GetInt32();
        var qid = CurrentQuestionId(factory, sessionId);
        var wrong = WrongAnswerId(factory, qid);

        await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = wrong });
        await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = wrong });

        var afterFail = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = wrong });
        Assert.Equal(HttpStatusCode.BadRequest, afterFail.StatusCode);
    }

    [Fact]
    public async Task SubmitMath_ForgedAnswerId_ReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "forger");

        var start = await StartAsync(client, "Math", "Logarithms");
        var sessionId = start.GetProperty("sessionId").GetInt32();

        var response = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, answerId = 999999 });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Submit_AnotherUsersSession_ReturnsNotFound()
    {
        using var factory = new QuestApiFactory();
        var owner = await CreateAuthenticatedClientAsync(factory, "owner_session");
        var intruder = await CreateAuthenticatedClientAsync(factory, "intruder_session");

        var start = await StartAsync(owner, "Math", "Logarithms");
        var sessionId = start.GetProperty("sessionId").GetInt32();
        var qid = CurrentQuestionId(factory, sessionId);

        var response = await intruder.PostAsJsonAsync("/api/test/submit",
            new { sessionId, answerId = CorrectAnswerId(factory, qid) });

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    // ----- submit: ukrainian ---------------------------------------------------

    [Fact]
    public async Task SubmitUkrainian_AllSlotsCorrect_CompletesAndAwardsXp()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "ua_winner");

        var start = await StartAsync(client, "Ukrainian", "Syntax");
        var sessionId = start.GetProperty("sessionId").GetInt32();
        var qid = CurrentQuestionId(factory, sessionId);

        var slots = Read(factory, db => db.Answers
            .Where(a => a.QuestionId == qid && a.CorrectSlotIndex != null)
            .Select(a => new { slotIndex = a.CorrectSlotIndex!.Value, answerId = a.Id })
            .ToList());

        var response = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, slots });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.True(doc.RootElement.GetProperty("correct").GetBoolean());
        Assert.True(doc.RootElement.GetProperty("completed").GetBoolean());
        Assert.Equal(slots.Count, doc.RootElement.GetProperty("slotResults").GetArrayLength());

        Assert.Equal(100, Read(factory, db => db.Users.Single(u => u.Username == "ua_winner").XP));
        Assert.True(Read(factory, db => db.UserTestSessions.Single(s => s.Id == sessionId).IsCompleted));
    }

    [Fact]
    public async Task SubmitUkrainian_OneSlotWrong_FailsWithSlotResults()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "ua_loser");

        var start = await StartAsync(client, "Ukrainian", "Syntax");
        var sessionId = start.GetProperty("sessionId").GetInt32();
        var qid = CurrentQuestionId(factory, sessionId);

        // Correct element for slot 0, but a distractor dropped into slot 1.
        var (correctSlot0, distractorId) = Read(factory, db =>
        {
            var c0 = db.Answers.Single(a => a.QuestionId == qid && a.CorrectSlotIndex == 0).Id;
            var d = db.Answers.First(a => a.QuestionId == qid && a.CorrectSlotIndex == null).Id;
            return (c0, d);
        });

        var slots = new[]
        {
            new { slotIndex = 0, answerId = correctSlot0 },
            new { slotIndex = 1, answerId = distractorId }
        };

        var response = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, slots });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        Assert.False(doc.RootElement.GetProperty("correct").GetBoolean());
        Assert.True(doc.RootElement.GetProperty("failed").GetBoolean());

        var results = doc.RootElement.GetProperty("slotResults").EnumerateArray().ToList();
        Assert.Contains(results, r => r.GetProperty("slotIndex").GetInt32() == 0 && r.GetProperty("isCorrect").GetBoolean());
        Assert.Contains(results, r => r.GetProperty("slotIndex").GetInt32() == 1 && !r.GetProperty("isCorrect").GetBoolean());

        Assert.True(Read(factory, db => db.UserTestSessions.Single(s => s.Id == sessionId).IsFailed));
        Assert.Equal(0, Read(factory, db => db.Users.Single(u => u.Username == "ua_loser").XP));
    }

    [Fact]
    public async Task SubmitUkrainian_DuplicateSlotIndex_ReturnsBadRequest_AndDoesNotConsumeSession()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "ua_dup");

        var start = await StartAsync(client, "Ukrainian", "Syntax");
        var sessionId = start.GetProperty("sessionId").GetInt32();
        var qid = CurrentQuestionId(factory, sessionId);
        var correctSlot0 = Read(factory, db => db.Answers.Single(a => a.QuestionId == qid && a.CorrectSlotIndex == 0).Id);

        // The same slot submitted twice (both correct) must not be treated as a permanent fail.
        var slots = new[]
        {
            new { slotIndex = 0, answerId = correctSlot0 },
            new { slotIndex = 0, answerId = correctSlot0 }
        };

        var response = await client.PostAsJsonAsync("/api/test/submit", new { sessionId, slots });
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        // The session is untouched: the player can still complete the scroll.
        var (failed, completed) = Read(factory, db =>
        {
            var s = db.UserTestSessions.Single(x => x.Id == sessionId);
            return (s.IsFailed, s.IsCompleted);
        });
        Assert.False(failed);
        Assert.False(completed);
    }

    // ----- static content ------------------------------------------------------

    [Fact]
    public async Task SeededFormulaImage_IsServedAsStaticFile()
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.GetAsync("/images/math/log_eq1.png");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("image/png", response.Content.Headers.ContentType?.MediaType);
    }
}
