using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.Models;
using System.Threading.Tasks;

namespace NMTales.Backend.Repositories.PlayerStats
{
    public class PlayerStatsRepository : Repository<Models.PlayerStats>, IPlayerStatsRepository
    {
        public PlayerStatsRepository(ApplicationDbContext context) : base(context)
        {
        }

        public async Task<Models.PlayerStats?> GetByUserIdAsync(int userId)
        {
            return await _dbSet.FirstOrDefaultAsync(ps => ps.UserId == userId);
        }
    }
}
