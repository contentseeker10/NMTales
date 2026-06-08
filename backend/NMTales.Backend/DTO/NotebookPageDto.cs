using NMTales.Backend.Models;

namespace NMTales.Backend.DTO;

public class NotebookPageDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;

    public static NotebookPageDto FromModel(NotebookPage page)
    {
        return new NotebookPageDto
        {
            Id = page.Id,
            Title = page.Title,
            Content = page.Content
        };
    }
}

public class CreateNotebookPageDto
{
    public string Title { get; set; } = string.Empty;
}

public class UpdateNotebookPageDto
{
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}