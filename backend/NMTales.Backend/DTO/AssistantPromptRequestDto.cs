namespace NMTales.Backend.DTO;

/// <summary>Body of a POST to <c>api/LLM/{subject}</c>: the player's message to the tutor.</summary>
public class AssistantPromptRequestDto
{
    public string Prompt { get; set; } = string.Empty;
}
