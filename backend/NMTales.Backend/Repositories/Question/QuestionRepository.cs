using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.enums;
using NMTales.Backend.Models;

namespace NMTales.Backend.Repositories
{
    public class QuestionRepository : Repository<Question>, IQuestionRepository
    {
        public QuestionRepository(ApplicationDbContext context) : base(context)
        {
        }

        public async Task<Question?> GetQuestionWithAnswersAsync(int id)
        {
            return await _dbSet
                .Include(q => q.Answers)
                .FirstOrDefaultAsync(q => q.Id == id);
        }

        public async Task<IEnumerable<Question>> GetQuestionsBySubjectAsync(Subject subject)
        {
            return await _dbSet
                .Where(q => q.Subject == subject)
                .ToListAsync();        }
    }
}
