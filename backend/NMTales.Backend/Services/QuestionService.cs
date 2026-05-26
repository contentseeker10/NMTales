using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.Models;

namespace NMTales.Backend.Services
{
    public class QuestionService
    {
        private readonly ApplicationDbContext _context;

        public QuestionService(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task<List<Question>> GetQuestions()
        {
            return await _context.Questions
                .Include(q => q.Answers)
                .ToListAsync();
        }

        public async Task<Question?> GetQuestionById(int id)
        {
            return await _context.Questions
                .Include(q => q.Answers)
                .FirstOrDefaultAsync(q => q.Id == id);
        }

        public async Task<bool> CheckAnswer(
            int questionId,
            int answerId)
        {
            var answer = await _context.Answers
                .FirstOrDefaultAsync(a =>
                    a.Id == answerId &&
                    a.QuestionId == questionId);

            if (answer == null)
            {
                return false;
            }

            return answer.IsCorrect;
        }
    }
}
