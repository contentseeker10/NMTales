using NMTales.Backend.enums;

namespace NMTales.Backend.Models;

/// <summary>
/// One stored line of an AI-tutor conversation. History is kept server-side per user and
/// subject so the tutor has context across turns and the client stays thin.
/// </summary>
public class AssistantMessage
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public Subject Subject { get; set; }

    /// <summary>"user" or "model" — matches the Gemini content role.</summary>
    public string Role { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
