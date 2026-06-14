using NMTales.Backend.DTO;
using NMTales.Backend.enums;
using NMTales.Backend.Models;

namespace NMTales.Backend.Services.Test;

public interface ITestService
{
    Task<List<UserTestSession>> GetStaleSessionsAsync(int userId);
    void RemoveSessions(IEnumerable<UserTestSession> sessions);
    Task<List<int>> SelectQuestionIdsAsync(int userId, Subject subject, string topic, int count);
    void AddSession(UserTestSession session);
    Task<UserTestSession?> GetSessionByIdAsync(int sessionId);
    Task<Models.User?> GetUserByIdAsync(int userId);
    Task<Question?> GetQuestionWithAnswersAsync(int questionId);
    Task SaveChangesAsync();
}