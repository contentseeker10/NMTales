using NMTales.Backend.Models;

namespace NMTales.Backend.Repositories.Notebook;

public interface INotebookRepository : IRepository<NotebookPage>
{
    Task<IEnumerable<NotebookPage>> GetAllByUserIdAsync(int userId);
    Task<bool> DeletePageAsync(int id, int userId);
    Task<int> GetPagesCountByUserIdAsync(int userId);
    Task<NotebookPage?> GetPageAsync(int id, int userId);

}