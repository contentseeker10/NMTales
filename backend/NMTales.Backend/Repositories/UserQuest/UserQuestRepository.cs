using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.Repositories.User;

namespace NMTales.Backend.Repositories.UserQuest;

public class UserQuestRepository : Repository<Models.UserQuest>, IUserQuestRepository
{
    public UserQuestRepository(ApplicationDbContext context) : base(context)
    {
    }

    public IQueryable<Models.UserQuest> GetCompletedQuestsByUserId(int userId)
    {
        return _dbSet.Where(q => q.UserId == userId && q.IsCompleted);
    }

    public async Task<Models.UserQuest?> GetUncompletedQuestByUserId(int userId)
    {
        return await _dbSet.FirstOrDefaultAsync(q => q.UserId == userId && !q.IsCompleted); 
    }

    public async Task<bool> HasAnyUncompletedQuestAsync(int userId)
    {
        return await  _dbSet.AnyAsync(q => q.UserId == userId && !q.IsCompleted);
    }

    public async Task<bool> HasCompletedQuestAsync(int userId, string npcId, string questId)
    {
        return await _dbSet.AnyAsync(uq => uq.UserId == userId && uq.NpcId == npcId && uq.QuestId == questId && uq.IsCompleted);
    }
}