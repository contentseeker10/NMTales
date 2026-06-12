using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.Models;

namespace NMTales.Backend.Repositories.Notebook;

public class NotebookRepository : Repository<NotebookPage>, INotebookRepository
{
    public NotebookRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<IEnumerable<NotebookPage>> GetAllByUserIdAsync(int userId)
    {
        return await _dbSet
            .Where(q => q.UserId == userId)
            .ToListAsync(); 
    }

    public async Task<bool> DeletePageAsync(int id, int userId)
    {
        var rowsAffected = await _dbSet.Where(n => n.Id == id && n.UserId == userId).ExecuteDeleteAsync<NotebookPage>();
        return rowsAffected > 0;
    }
}