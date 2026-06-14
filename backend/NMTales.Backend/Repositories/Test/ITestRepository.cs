using NMTales.Backend.enums;
using NMTales.Backend.Models;

namespace NMTales.Backend.Repositories.Test;

public interface ITestRepository
{
    Task<List<UserTestSession>> GetStaleSessionsAsync(int userId);
    void RemoveSessions(IEnumerable<UserTestSession> sessions);
    Task<List<int>> GetQuestionIdsByTopicAsync(Subject subject, string topic);
    Task<HashSet<int>> GetCompletedQuestionIdsAsync(int userId);
    void AddSession(UserTestSession session);
    Task<UserTestSession?> GetSessionByIdAsync(int sessionId);
    Task<Models.User?> GetUserByIdAsync(int userId);
    Task<Question?> GetQuestionWithAnswersAsync(int questionId);
    Task SaveChangesAsync();
}