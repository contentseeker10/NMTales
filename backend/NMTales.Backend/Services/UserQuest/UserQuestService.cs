using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Repositories.UserQuest;

namespace NMTales.Backend.Services.UserQuest;

public class UserQuestService : IUserQuestService
{
    private readonly IUserQuestRepository _userQuestRepository;
    public UserQuestService(IUserQuestRepository userQuestRepository)
    {
        _userQuestRepository = userQuestRepository;
    }

    public async Task<IEnumerable<string>> GetCompletedQuestsIdsAsync(int userId)
    {
        var query = _userQuestRepository.GetCompletedQuestsByUserId(userId);

        var summaries = await query
            .Select(uq => $"{uq.NpcId}:{uq.QuestId}").
            ToListAsync(); 

        return summaries;
        
    }

    public async Task<Models.UserQuest?> GetUncompletedQuestAsync(int userId)
    {
        return await _userQuestRepository.GetUncompletedQuestByUserId(userId);
    }

    public async Task<bool> HasAnyUncompletedQuestAsync(int userId)
    {
        return await _userQuestRepository.HasAnyUncompletedQuestAsync(userId);
    }

    public async Task SaveChangesAsync()
    {
        await _userQuestRepository.SaveChangesAsync();
    }

    public async Task AddQuestAsync(Models.UserQuest userQuest)
    {
        await _userQuestRepository.AddAsync(userQuest);
        await _userQuestRepository.SaveChangesAsync();
    }

    public async Task<bool> HasCompletedQuestAsync(int userId, string npcId, string questId)
    {
        return await _userQuestRepository.HasCompletedQuestAsync(userId, npcId, questId);
    }
}