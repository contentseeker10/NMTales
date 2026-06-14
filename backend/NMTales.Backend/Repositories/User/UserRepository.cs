using Microsoft.EntityFrameworkCore;
using System.Threading.Tasks;
using NMTales.Backend.Data;
using NMTales.Backend.Models;
using NMTales.Backend.Repositories.User;

namespace NMTales.Backend.Repositories;

public class UserRepository : Repository<Models.User>, IUserRepository
{
    public UserRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<Models.User?> GetByUsernameAsync(string username)
    {
        return await _dbSet.FirstOrDefaultAsync(u => u.Username == username);
    }

    public async Task<bool> UsernameExistsAsync(string username)
    {
        return await _dbSet.AnyAsync(u => u.Username == username);
    }

}