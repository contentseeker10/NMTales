using System.ComponentModel.DataAnnotations;

namespace NMTales.Backend.Models;

public class UserQuest
{
    public int Id { get; set; }

    [Required]
    public int UserId { get; set; }

    [Required]
    public string QuestId { get; set; } = string.Empty; // e.g., "quest_1"

    [Required]
    public string NpcId { get; set; } = string.Empty; // e.g., "npc_test"

    [Required]
    public int CurrentAmount { get; set; }

    [Required]
    public bool IsCompleted { get; set; }
}
