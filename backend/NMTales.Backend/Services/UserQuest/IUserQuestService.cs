namespace NMTales.Backend.Services.UserQuest;

public interface IUserQuestService
{
    Task<IEnumerable<string>> GetCompletedQuestsIdsAsync(int userId);
    Task<Models.UserQuest?> GetUncompletedQuestAsync(int userId);
    Task<bool> HasAnyUncompletedQuestAsync(int userId);
    Task SaveChangesAsync();
    Task AddQuestAsync(Models.UserQuest userQuest);
    Task<bool> HasCompletedQuestAsync(int userId, string npcId, string questId);
}