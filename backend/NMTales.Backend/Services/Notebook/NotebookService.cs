using NMTales.Backend.Models;
using NMTales.Backend.Repositories;
using NMTales.Backend.Repositories.Notebook;

namespace NMTales.Backend.Services;

public class NotebookService : INotebookService
{
    private int MaxPagesPerUser = 10;
    private readonly INotebookRepository _notebookPageRepository;
    
    public NotebookService(INotebookRepository notebookPageRepository)
    {
        this._notebookPageRepository = notebookPageRepository;
    }
    
    public async Task<IEnumerable<NotebookPage>> GetAllPagesAsync(int userId)
    {
        return await _notebookPageRepository.GetAllByUserIdAsync(userId);
    }

    public async Task<NotebookPage?> CreatePageAsync(int userId, string title)
    {
        var userPagesCount = await _notebookPageRepository.GetPagesCountByUserIdAsync(userId);
        if (userPagesCount >= MaxPagesPerUser) return null;

        var page = new NotebookPage
        {
            UserId = userId,
            Title = title,
            Content = "",
            CreatedAt = DateTime.UtcNow
        };

        await _notebookPageRepository.AddAsync(page);
        await _notebookPageRepository.SaveChangesAsync();

        return page;
    }

    public async Task<bool> UpdatePageAsync(int id, int userId, string title, string content)
    {
        var page = await _notebookPageRepository.GetByIdAsync(id);
        if (page == null) return false;
        if (page.UserId != userId)
        {
            throw new UnauthorizedAccessException("Forbidden: You do not own this page.");
        }
        
        page.Title = title;
        page.Content = content;
        
        _notebookPageRepository.Update(page);
        await _notebookPageRepository.SaveChangesAsync();

        return true;
    }

    public async Task<bool> DeletePageAsync(int id, int userId)
    {
        bool deleted = await _notebookPageRepository.DeletePageAsync(id, userId);
        await _notebookPageRepository.SaveChangesAsync();
        return deleted;
    }

    public async Task<int> GetPagesCountByUserIdAsync(int userId)
    {
        return await _notebookPageRepository.GetPagesCountByUserIdAsync(userId); 
    }

    public async Task AddNotebookPageAsync(NotebookPage notebookPage)
    {
        await _notebookPageRepository.AddAsync(notebookPage);
        await _notebookPageRepository.SaveChangesAsync();
    }
}