using System.Collections.Concurrent;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.enums;
using NMTales.Backend.Models;
using NMTales.Backend.Services;

namespace NMTales.Backend.Controllers;

/// <summary>
/// AI tutor chat. The server owns the Gemini API key, the subject persona, and the
/// conversation history; the client only sends a prompt and renders the answer.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LLMController : ControllerBase
{
    // Upper bound on a single player message; keeps prompts sane and bounds token usage.
    private const int MaxPromptLength = 2000;

    // How many recent turns (user + model lines) to feed back to Gemini as context.
    private const int MaxHistoryTurns = 24;

    // Serialize a user's writes to one conversation so concurrent sends can't interleave the
    // stored user/model lines. Mirrors TestController's per-user gate.
    private static readonly ConcurrentDictionary<string, SemaphoreSlim> ConversationGates = new();

    private readonly ApplicationDbContext _context;
    private readonly GeminiService _gemini;

    public LLMController(ApplicationDbContext context, GeminiService gemini)
    {
        _context = context;
        _gemini = gemini;
    }

    /// <summary>Return the saved conversation for this user + subject so the client can restore it.</summary>
    [HttpGet("{subject}")]
    public async Task<IActionResult> GetConversation(string subject)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        if (!AssistantPersona.TryParseSubject(subject, out var parsed)) return BadRequest("Unknown subject.");

        var messages = await _context.AssistantMessages
            .Where(m => m.UserId == userId && m.Subject == parsed)
            .OrderBy(m => m.Id)
            .Select(m => AssistantMessageDto.FromModel(m))
            .ToListAsync();

        return Ok(new { subject = parsed.ToString(), messages });
    }

    /// <summary>Send the player's message to the tutor and return its reply.</summary>
    [HttpPost("{subject}")]
    public async Task<IActionResult> SendMessage(
        string subject, [FromBody] AssistantPromptRequestDto dto, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        if (!AssistantPersona.TryParseSubject(subject, out var parsed)) return BadRequest("Unknown subject.");

        var prompt = (dto.Prompt ?? string.Empty).Trim();
        if (prompt.Length == 0) return BadRequest("Prompt is required.");
        if (prompt.Length > MaxPromptLength) return BadRequest("Prompt is too long.");

        if (!_gemini.IsConfigured)
        {
            return StatusCode(StatusCodes.Status503ServiceUnavailable,
                new { error = "Асистент тимчасово недоступний." });
        }

        var gate = GateFor(userId, parsed);
        await gate.WaitAsync(ct);
        try
        {
            var stored = await _context.AssistantMessages
                .Where(m => m.UserId == userId && m.Subject == parsed)
                .OrderBy(m => m.Id)
                .ToListAsync(ct);

            var turns = BuildTurns(stored, prompt);
            var systemInstruction = AssistantPersona.SystemInstruction(parsed);

            var result = await _gemini.GenerateAsync(systemInstruction, turns, ct);
            if (!result.Ok)
            {
                // Upstream (Gemini) problem: surface as a gateway error, nothing persisted.
                return StatusCode(StatusCodes.Status502BadGateway, new { error = result.Error });
            }

            _context.AssistantMessages.Add(new AssistantMessage
            {
                UserId = userId, Subject = parsed, Role = "user", Content = prompt
            });
            _context.AssistantMessages.Add(new AssistantMessage
            {
                UserId = userId, Subject = parsed, Role = "model", Content = result.Text
            });
            await _context.SaveChangesAsync(ct);

            return Ok(new { answer = result.Text });
        }
        finally
        {
            gate.Release();
        }
    }

    /// <summary>Clear the conversation for this user + subject.</summary>
    [HttpDelete("{subject}")]
    public async Task<IActionResult> ResetConversation(string subject)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();
        if (!AssistantPersona.TryParseSubject(subject, out var parsed)) return BadRequest("Unknown subject.");

        var messages = await _context.AssistantMessages
            .Where(m => m.UserId == userId && m.Subject == parsed)
            .ToListAsync();

        if (messages.Count > 0)
        {
            _context.AssistantMessages.RemoveRange(messages);
            await _context.SaveChangesAsync();
        }

        return NoContent();
    }

    /// <summary>
    /// Map stored history + the new prompt to Gemini turns, keeping only the most recent
    /// <see cref="MaxHistoryTurns"/> and ensuring the sequence starts with a "user" turn
    /// (Gemini rejects histories that open on a "model" turn).
    /// </summary>
    private static List<GeminiTurn> BuildTurns(List<AssistantMessage> stored, string prompt)
    {
        var turns = new List<GeminiTurn>(stored.Count + 1);
        foreach (var message in stored)
        {
            turns.Add(new GeminiTurn(message.Role, message.Content));
        }
        turns.Add(new GeminiTurn("user", prompt));

        if (turns.Count > MaxHistoryTurns)
        {
            turns.RemoveRange(0, turns.Count - MaxHistoryTurns);
        }
        while (turns.Count > 0 && turns[0].Role == "model")
        {
            turns.RemoveAt(0);
        }

        return turns;
    }

    private bool TryGetUserId(out int userId)
    {
        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(userIdValue, out userId);
    }

    private static SemaphoreSlim GateFor(int userId, Subject subject) =>
        ConversationGates.GetOrAdd($"{userId}:{subject}", _ => new SemaphoreSlim(1, 1));
}
