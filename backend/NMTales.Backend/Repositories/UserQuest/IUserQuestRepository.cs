namespace NMTales.Backend.Repositories.UserQuest;

public interface IUserQuestRepository : IRepository<Models.UserQuest>
{
    IQueryable<Models.UserQuest> GetCompletedQuestsByUserId(int userId);
    Task<Models.UserQuest?> GetUncompletedQuestByUserId(int userId);
    Task<bool> HasAnyUncompletedQuestAsync(int userId);
    Task<bool> HasCompletedQuestAsync(int userId, string npcId, string questId);

}