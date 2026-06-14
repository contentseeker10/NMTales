using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.enums;
using NMTales.Backend.Models;

namespace NMTales.Backend.Repositories.Test;

public class TestRepository : ITestRepository
{
    private readonly ApplicationDbContext _context;

    public TestRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<UserTestSession>> GetStaleSessionsAsync(int userId)
    {
        return await _context.UserTestSessions
            .Where(s => s.UserId == userId && !s.IsCompleted)
            .ToListAsync();
    }

    public void RemoveSessions(IEnumerable<UserTestSession> sessions)
    {
        _context.UserTestSessions.RemoveRange(sessions);
    }

    public async Task<List<int>> GetQuestionIdsByTopicAsync(Subject subject, string topic)
    {
        return await _context.Questions
            .Where(q => q.Subject == subject && q.Topic == topic)
            .Select(q => q.Id)
            .ToListAsync();
    }

    public async Task<HashSet<int>> GetCompletedQuestionIdsAsync(int userId)
    {
        var completedSessions = await _context.UserTestSessions
            .Where(s => s.UserId == userId && s.IsCompleted)
            .ToListAsync();
            
        return completedSessions
            .SelectMany(s => s.QuestionIds)
            .ToHashSet();
    }

    public void AddSession(UserTestSession session)
    {
        _context.UserTestSessions.Add(session);
    }

    public async Task<UserTestSession?> GetSessionByIdAsync(int sessionId)
    {
        return await _context.UserTestSessions.FirstOrDefaultAsync(s => s.Id == sessionId);
    }

    public async Task<Models.User?> GetUserByIdAsync(int userId)
    {
        return await _context.Users.FindAsync(userId);
    }

    public async Task<Question?> GetQuestionWithAnswersAsync(int questionId)
    {
        return await _context.Questions
            .Include(q => q.Answers)
            .FirstOrDefaultAsync(q => q.Id == questionId);
    }

    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }
}