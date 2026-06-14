using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace NMTales.Backend.Services;

/// <summary>One turn of a chat: <c>Role</c> is "user" or "model".</summary>
public readonly record struct GeminiTurn(string Role, string Text);

/// <summary>Outcome of a generation call. On failure <c>Error</c> holds a user-facing message.</summary>
public readonly record struct GeminiResult(bool Ok, string Text, string Error)
{
    public static GeminiResult Success(string text) => new(true, text, string.Empty);
    public static GeminiResult Failure(string error) => new(false, string.Empty, error);
}

/// <summary>
/// Server-side client for the Google AI Studio (Gemini) <c>generateContent</c> endpoint. The
/// API key lives here (server) and never reaches the game client.
/// </summary>
public class GeminiService
{
    private static readonly JsonSerializerOptions SerializerOptions = new()
    {
        DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull,
    };

    private readonly HttpClient _http;
    private readonly GeminiOptions _options;
    private readonly ILogger<GeminiService> _logger;

    public GeminiService(HttpClient http, IOptions<GeminiOptions> options, ILogger<GeminiService> logger)
    {
        _http = http;
        _options = options.Value;
        _logger = logger;
    }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(_options.ApiKey);

    public async Task<GeminiResult> GenerateAsync(
        string systemInstruction, IReadOnlyList<GeminiTurn> history, CancellationToken ct)
    {
        if (!IsConfigured)
        {
            return GeminiResult.Failure("Асистент не налаштований на сервері.");
        }

        var payload = new
        {
            systemInstruction = new { parts = new[] { new { text = systemInstruction } } },
            contents = history.Select(t => new
            {
                role = t.Role,
                parts = new[] { new { text = t.Text } }
            }),
            generationConfig = new
            {
                temperature = _options.Temperature,
                maxOutputTokens = _options.MaxOutputTokens,
                thinkingConfig = new { thinkingBudget = _options.ThinkingBudget }
            }
        };

        var url = $"{_options.BaseUrl.TrimEnd('/')}/models/{_options.Model}:generateContent";

        using var request = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent(
                JsonSerializer.Serialize(payload, SerializerOptions), Encoding.UTF8, "application/json")
        };
        request.Headers.TryAddWithoutValidation("x-goog-api-key", _options.ApiKey);

        HttpResponseMessage response;
        string body;
        try
        {
            response = await _http.SendAsync(request, ct);
            body = await response.Content.ReadAsStringAsync(ct);
        }
        catch (TaskCanceledException) when (!ct.IsCancellationRequested)
        {
            _logger.LogWarning("Gemini request timed out.");
            return GeminiResult.Failure("Асистент не відповів вчасно. Спробуй ще раз.");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogError(ex, "Gemini request failed.");
            return GeminiResult.Failure("Не вдалося з'єднатися з сервісом асистента.");
        }

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning("Gemini returned {Status}: {Body}", (int)response.StatusCode, body);
            return GeminiResult.Failure(FriendlyHttpError((int)response.StatusCode));
        }

        return ParseSuccessBody(body);
    }

    private GeminiResult ParseSuccessBody(string body)
    {
        try
        {
            using var doc = JsonDocument.Parse(body);
            var root = doc.RootElement;

            // Whole prompt rejected before any generation.
            if (root.TryGetProperty("promptFeedback", out var feedback) &&
                feedback.TryGetProperty("blockReason", out var blockReason))
            {
                return GeminiResult.Failure($"Запит заблоковано ({blockReason.GetString()}).");
            }

            if (!root.TryGetProperty("candidates", out var candidates) ||
                candidates.ValueKind != JsonValueKind.Array ||
                candidates.GetArrayLength() == 0)
            {
                return GeminiResult.Failure("Порожня відповідь від асистента.");
            }

            var candidate = candidates[0];
            var finishReason = candidate.TryGetProperty("finishReason", out var fr)
                ? fr.GetString() ?? string.Empty
                : string.Empty;

            var text = new StringBuilder();
            if (candidate.TryGetProperty("content", out var content) &&
                content.TryGetProperty("parts", out var parts) &&
                parts.ValueKind == JsonValueKind.Array)
            {
                foreach (var part in parts.EnumerateArray())
                {
                    if (part.TryGetProperty("text", out var t))
                    {
                        text.Append(t.GetString());
                    }
                }
            }

            var answer = text.ToString().Trim();
            if (answer.Length == 0)
            {
                return GeminiResult.Failure(finishReason switch
                {
                    "SAFETY" or "PROHIBITED_CONTENT" => "Відповідь заблоковано системою безпеки.",
                    "RECITATION" => "Не можу відповісти на це питання.",
                    _ => $"Асистент не дав відповіді ({finishReason})."
                });
            }

            return GeminiResult.Success(answer);
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Could not parse Gemini response.");
            return GeminiResult.Failure("Некоректна відповідь від асистента.");
        }
    }

    private static string FriendlyHttpError(int status) => status switch
    {
        400 => "Некоректний запит до асистента.",
        401 or 403 => "Немає доступу до сервісу асистента.",
        429 => "Забагато запитів. Спробуй ще раз за хвилину.",
        >= 500 => "Сервіс асистента тимчасово недоступний.",
        _ => $"Помилка асистента ({status})."
    };
}
