using NMTales.Backend.Models;

namespace NMTales.Backend.Repositories.User;

public interface IUserRepository : IRepository<Models.User> 
{
    Task<Models.User?> GetByUsernameAsync(string username);
    Task<bool> UsernameExistsAsync(string username);
}