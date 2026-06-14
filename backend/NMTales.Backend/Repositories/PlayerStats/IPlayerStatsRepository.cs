using System.Threading.Tasks;
using NMTales.Backend.Models;

namespace NMTales.Backend.Repositories.PlayerStats
{
    public interface IPlayerStatsRepository : IRepository<Models.PlayerStats>
    {
        Task<Models.PlayerStats?> GetByUserIdAsync(int userId);
    }
}
