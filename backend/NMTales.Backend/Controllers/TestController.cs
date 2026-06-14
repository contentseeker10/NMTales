using System.Collections.Concurrent;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.enums;
using NMTales.Backend.Models;
using NMTales.Backend.Services;
using NMTales.Backend.Services.Test;
using NMTales.Backend.Repositories;

namespace NMTales.Backend.Controllers;

/// <summary>
/// Stateful, server-authoritative test runner. The server picks the questions, tracks
/// progress in <see cref="UserTestSession"/>, and validates every answer against the
/// database so the client never learns which option is correct and cannot fake a pass.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class TestController : ControllerBase
{
    // XP granted for completing a test, mirroring the quest reward model.
    private const int XpReward = 100;

    // Default attempts per math question.
    private const int MathAttempts = 2;

    // Serialize start/submit per user so the check-then-act sequence is atomic and a session
    // can never be advanced or rewarded twice by racing requests. Mirrors QuestController's
    // anti-cheat gate; for a multi-instance relational deployment add a concurrency token.
    private static readonly ConcurrentDictionary<int, SemaphoreSlim> UserGates = new();

    private readonly ITestService _testService;
    private readonly IAchievementService _achievementService;
    private readonly IRepository<PlayerStats> _playerStatsRepository;

    public TestController(
        ITestService testService, 
        IAchievementService achievementService,
        IRepository<PlayerStats> playerStatsRepository)
    {
        _testService = testService;
        _achievementService = achievementService;
        _playerStatsRepository = playerStatsRepository;
    }

    /// <summary>
    /// Start a test: pick the questions, create a fresh session, and return the first question
    /// (without any correctness flags).
    /// </summary>
    [HttpPost("start")]
    public async Task<IActionResult> Start([FromBody] StartTestRequestDto dto)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        if (!Enum.TryParse<Subject>(dto.Subject, ignoreCase: true, out var subject))
        {
            return BadRequest("Unknown subject.");
        }

        var topic = (dto.Topic ?? string.Empty).Trim();
        if (topic.Length == 0)
        {
            return BadRequest("Topic is required.");
        }

        var requiredCount = subject == Subject.Math ? 3 : 1;

        var gate = GateFor(userId);
        await gate.WaitAsync();
        try
        {
            var stale = await _testService.GetStaleSessionsAsync(userId);
            if (stale.Count > 0)
            {
                _testService.RemoveSessions(stale);
            }

            var questionIds = await _testService.SelectQuestionIdsAsync(userId, subject, topic, requiredCount);
            if (questionIds.Count < requiredCount)
            {
                return BadRequest("Not enough questions available for this topic.");
            }

            var session = new UserTestSession
            {
                UserId = userId,
                Subject = subject,
                Topic = topic,
                QuestionIds = questionIds,
                CurrentQuestionIndex = 0,
                RemainingAttempts = subject == Subject.Math ? MathAttempts : 1,
                IsCompleted = false,
                IsFailed = false
            };

            _testService.AddSession(session);
            await _testService.SaveChangesAsync();

            var firstQuestion = await LoadQuestionDtoAsync(questionIds[0]);
            if (firstQuestion == null)
            {
                return BadRequest("Selected question could not be loaded.");
            }

            return Ok(new StartTestResponseDto
            {
                SessionId = session.Id,
                Subject = subject.ToString(),
                Topic = topic,
                CurrentQuestionIndex = 0,
                TotalQuestions = questionIds.Count,
                Question = firstQuestion
            });
        }
        finally
        {
            gate.Release();
        }
    }

    /// <summary>
    /// Submit an answer for the current question. Dispatches on the session's subject:
    /// math validates a single answer id; the Ukrainian scroll validates slot assignments.
    /// </summary>
    [HttpPost("submit")]
    public async Task<IActionResult> Submit([FromBody] SubmitTestRequestDto dto)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var gate = GateFor(userId);
        await gate.WaitAsync();
        try
        {
            var session = await _testService.GetSessionByIdAsync(dto.SessionId);

            // Treat "not yours" as "not found" so sessions can't be enumerated across users.
            if (session == null || session.UserId != userId)
            {
                return NotFound("Test session not found.");
            }

            if (session.IsCompleted) return BadRequest("This test is already completed.");
            if (session.IsFailed) return BadRequest("This test has already failed.");

            // Guards against a corrupt session whose index ran past its question list.
            if (session.CurrentQuestionIndex < 0 ||
                session.CurrentQuestionIndex >= session.QuestionIds.Count)
            {
                return BadRequest("Test session is in an invalid state.");
            }

            var user = await _testService.GetUserByIdAsync(userId);
            if (user == null) return Unauthorized();

            var currentQuestionId = session.QuestionIds[session.CurrentQuestionIndex];
            var question = await _testService.GetQuestionWithAnswersAsync(currentQuestionId);

            if (question == null)
            {
                return BadRequest("Current question could not be loaded.");
            }

            return session.Subject == Subject.Ukrainian
                ? await SubmitUkrainianAsync(dto, session, question, user)
                : await SubmitMathAsync(dto, session, question, user);
        }
        finally
        {
            gate.Release();
        }
    }

    // --- Math: one answer id, up to RemainingAttempts tries per question --------------------
    private async Task<IActionResult> SubmitMathAsync(
        SubmitTestRequestDto dto, UserTestSession session, Question question, User user)
    {
        if (!dto.AnswerId.HasValue)
        {
            return BadRequest("answerId is required for this test.");
        }

        // The answer must belong to the current question; otherwise it's a malformed/forged id.
        var submitted = question.Answers.FirstOrDefault(a => a.Id == dto.AnswerId.Value);
        if (submitted == null)
        {
            return BadRequest("Answer does not belong to the current question.");
        }

        if (submitted.IsCorrect)
        {
            var isLastQuestion = session.CurrentQuestionIndex + 1 >= session.QuestionIds.Count;

            if (isLastQuestion)
            {
                session.CurrentQuestionIndex++;
                session.RemainingAttempts = MathAttempts;
                session.IsCompleted = true;
                user.AddXp(XpReward);
                await _testService.SaveChangesAsync();
                return Ok(new { correct = true, completed = true });
            }

            // Load the next question BEFORE advancing so a load failure can't persist an index
            // the session could never serve (which would wedge the run on every later submit).
            var nextQuestion = await LoadQuestionDtoAsync(session.QuestionIds[session.CurrentQuestionIndex + 1]);
            if (nextQuestion == null)
            {
                return BadRequest("Next question could not be loaded.");
            }

            session.CurrentQuestionIndex++;
            session.RemainingAttempts = MathAttempts;
            await _testService.SaveChangesAsync();
            return Ok(new { correct = true, completed = false, nextQuestion });
        }

        session.RemainingAttempts--;
        if (session.RemainingAttempts <= 0)
        {
            session.IsFailed = true;
            var statsList = await _playerStatsRepository.GetAllAsync();
            var stats = statsList.FirstOrDefault(ps => ps.UserId == user.Id);
            if (stats == null)
            {
                stats = new PlayerStats { UserId = user.Id };
                await _playerStatsRepository.AddAsync(stats);
            }
            stats.FailedTestsCount++;
            stats.HasFailedTest = true;
            await _playerStatsRepository.SaveChangesAsync();

            await _testService.SaveChangesAsync();

            await _achievementService.EvaluateAndUnlockAchievementsAsync(user.Id);
            return Ok(new { correct = false, completed = false, failed = true });
        }

        await _testService.SaveChangesAsync();
        return Ok(new
        {
            correct = false,
            completed = false,
            failed = false,
            remainingAttempts = session.RemainingAttempts
        });
    }

    // --- Ukrainian: drag answers into slots; any wrong slot fails the scroll ----------------
    private async Task<IActionResult> SubmitUkrainianAsync(
        SubmitTestRequestDto dto, UserTestSession session, Question question, User user)
    {
        if (dto.Slots == null || dto.Slots.Count == 0)
        {
            return BadRequest("slots are required for this test.");
        }

        // A placeholder holds exactly one element, so a repeated slot index is malformed input.
        // Reject it (the player can retry) rather than silently failing an otherwise-correct
        // scroll — the success check below counts raw submissions, so a duplicate would taint it.
        if (dto.Slots.Select(s => s.SlotIndex).Distinct().Count() != dto.Slots.Count)
        {
            return BadRequest("Each slot may be submitted at most once.");
        }

        // Slots that actually need filling (distractors have a null CorrectSlotIndex).
        var requiredSlots = question.Answers
            .Where(a => a.CorrectSlotIndex.HasValue)
            .Select(a => a.CorrectSlotIndex!.Value)
            .ToHashSet();

        var slotResults = new List<object>();
        var filledCorrectly = new HashSet<int>();

        foreach (var slot in dto.Slots)
        {
            var answer = question.Answers.FirstOrDefault(a => a.Id == slot.AnswerId);
            var isCorrect = answer != null && answer.CorrectSlotIndex == slot.SlotIndex;
            if (isCorrect)
            {
                filledCorrectly.Add(slot.SlotIndex);
            }

            slotResults.Add(new { slotIndex = slot.SlotIndex, isCorrect });
        }

        // Success only when every required slot is filled with its correct element and nothing
        // submitted was wrong.
        var success = filledCorrectly.SetEquals(requiredSlots)
                      && filledCorrectly.Count == dto.Slots.Count;

        if (success)
        {
            session.IsCompleted = true;
            user.AddXp(XpReward);
            await _testService.SaveChangesAsync();
            return Ok(new { correct = true, completed = true, failed = false, slotResults });
        }

        session.IsFailed = true;
        var statsList = await _playerStatsRepository.GetAllAsync();
        var stats = statsList.FirstOrDefault(ps => ps.UserId == user.Id);
        if (stats == null)
        {
            stats = new PlayerStats { UserId = user.Id };
            await _playerStatsRepository.AddAsync(stats);
        }
        stats.FailedTestsCount++;
        stats.HasFailedTest = true;
        await _playerStatsRepository.SaveChangesAsync();

        await _testService.SaveChangesAsync();

        await _achievementService.EvaluateAndUnlockAchievementsAsync(user.Id);
        return Ok(new { correct = false, completed = false, failed = true, slotResults });
    }
    
    private async Task<TestQuestionDto?> LoadQuestionDtoAsync(int questionId)
    {
        var question = await _testService.GetQuestionWithAnswersAsync(questionId);
        return question == null ? null : TestQuestionDto.FromModel(question);
    }

    private bool TryGetUserId(out int userId)
    {
        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(userIdValue, out userId);
    }

    private static SemaphoreSlim GateFor(int userId) =>
        UserGates.GetOrAdd(userId, _ => new SemaphoreSlim(1, 1));
}
