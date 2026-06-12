using NMTales.Backend.Models;

namespace NMTales.Backend.Services;

public interface INotebookService
{
    Task<IEnumerable<NotebookPage>> GetAllPagesAsync(int userId);
    Task<NotebookPage?> CreatePageAsync(int userId, string title);
    Task<bool> UpdatePageAsync(int id, int userId, string title, string content);
    Task<bool> DeletePageAsync(int id, int userId);
}