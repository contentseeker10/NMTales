using System.Threading.Tasks;
using NMTales.Backend.Models;
using NMTales.Backend.enums;

namespace NMTales.Backend.Repositories
{
    public interface IQuestionRepository : IRepository<Question>
    {
        Task<Question?> GetQuestionWithAnswersAsync(int id);
        Task<IEnumerable<Question>> GetQuestionsBySubjectAsync(Subject subject);
    }
}