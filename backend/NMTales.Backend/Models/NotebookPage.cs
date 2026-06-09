using System.ComponentModel.DataAnnotations;

namespace NMTales.Backend.Models;

public class NotebookPage
{
    public int Id { get; set; }

    public int UserId { get; set; }
    public User? User { get; set; }

    [Required]
    [MaxLength(20)]
    public string Title { get; set; } = string.Empty;

    [MaxLength(10000)]
    public string Content { get; set; } = "Тут будуть потужні записи...";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}