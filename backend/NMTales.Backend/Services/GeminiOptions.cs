namespace NMTales.Backend.Services;

/// <summary>
/// Bound from the "Gemini" configuration section. The API key is kept out of source control:
/// supply it via user-secrets (<c>dotnet user-secrets set "Gemini:ApiKey" ...</c>) or the
/// <c>Gemini__ApiKey</c> environment variable. <see cref="appsettings.json"/> only holds the
/// non-secret defaults (model, base url).
/// </summary>
public class GeminiOptions
{
    public const string SectionName = "Gemini";

    public string ApiKey { get; set; } = string.Empty;

    public string Model { get; set; } = "gemini-2.5-flash";

    public string BaseUrl { get; set; } = "https://generativelanguage.googleapis.com/v1beta";

    /// <summary>Sampling temperature for tutor replies.</summary>
    public double Temperature { get; set; } = 0.7;

    /// <summary>Hard cap on a single reply length.</summary>
    public int MaxOutputTokens { get; set; } = 2048;

    /// <summary>
    /// Gemini 2.5 "thinking" budget in tokens. 0 disables it, which cuts reply latency from
    /// ~4s to ~1s with no quality loss for short tutoring answers.
    /// </summary>
    public int ThinkingBudget { get; set; } = 0;
}
