using NMTales.Backend.Models;

namespace NMTales.Backend.DTO;

/// <summary>A single chat line returned to the client when it restores a conversation.</summary>
public class AssistantMessageDto
{
    public string Role { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public static AssistantMessageDto FromModel(AssistantMessage message) => new()
    {
        Role = message.Role,
        Content = message.Content
    };
}
