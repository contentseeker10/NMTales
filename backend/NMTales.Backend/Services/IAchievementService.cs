using NMTales.Backend.Models;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace NMTales.Backend.Services
{
    public interface IAchievementService
    {
        Task<List<Achievement>> EvaluateAndUnlockAchievementsAsync(int userId);
    }
}
