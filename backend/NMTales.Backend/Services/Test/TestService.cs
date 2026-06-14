using NMTales.Backend.enums;
using NMTales.Backend.Models;
using NMTales.Backend.Repositories.Test;

namespace NMTales.Backend.Services.Test;

public class TestService : ITestService
{
    private readonly ITestRepository _repository;

    public TestService(ITestRepository repository)
    {
        _repository = repository;
    }

    public async Task<List<UserTestSession>> GetStaleSessionsAsync(int userId)
    {
        return await _repository.GetStaleSessionsAsync(userId);
    }

    public void RemoveSessions(IEnumerable<UserTestSession> sessions)
    {
        _repository.RemoveSessions(sessions);
    }

    /// <summary>
    /// Choose unique random question ids for a topic, preferring questions the player has not
    /// yet answered correctly (questions inside their completed sessions), then falling back to
    /// already-seen ones if the fresh pool is too small.
    /// </summary>
    public async Task<List<int>> SelectQuestionIdsAsync(int userId, Subject subject, string topic, int count)
    {
        // 1. Ask the repository for raw data
        var candidateIds = await _repository.GetQuestionIdsByTopicAsync(subject, topic);
        if (candidateIds.Count < count)
        {
            return candidateIds;
        }

        var answeredCorrectly = await _repository.GetCompletedQuestionIdsAsync(userId);

        // 2. Perform the business logic (randomization and filtering) here in the service
        var fresh = candidateIds
            .Where(id => !answeredCorrectly.Contains(id))
            .OrderBy(_ => Random.Shared.Next())
            .ToList();
            
        var seen = candidateIds
            .Where(id => answeredCorrectly.Contains(id))
            .OrderBy(_ => Random.Shared.Next())
            .ToList();

        return fresh.Concat(seen).Take(count).ToList();
    }

    public void AddSession(UserTestSession session)
    {
        _repository.AddSession(session);
    }

    public async Task<UserTestSession?> GetSessionByIdAsync(int sessionId)
    {
        return await _repository.GetSessionByIdAsync(sessionId);
    }

    public async Task<Models.User?> GetUserByIdAsync(int userId)
    {
        return await _repository.GetUserByIdAsync(userId);
    }

    public async Task<Question?> GetQuestionWithAnswersAsync(int questionId)
    {
        return await _repository.GetQuestionWithAnswersAsync(questionId);
    }

    public async Task SaveChangesAsync()
    {
        await _repository.SaveChangesAsync();
    }
}