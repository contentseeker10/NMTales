using NMTales.Backend.Models;
using NMTales.Backend.Repositories.User;

namespace NMTales.Backend.Services.Player;

public class PlayerService : IPlayerService
{
    private readonly IUserRepository _userRepo;

    public PlayerService(IUserRepository userRepo)
    {
        _userRepo = userRepo;
    }

    public async Task<User?> GetPlayerAsync(int userId)
    {
        return await _userRepo.GetByIdAsync(userId);
    }

    public async Task<User?> UpdateLocationAsync(int userId, string location, double x, double y)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        
        if (user == null)
        {
            return null;
        }

        user.CurrentLocation = location;
        user.CurrentPositionX = x;
        user.CurrentPositionY = y;

        await _userRepo.SaveChangesAsync();
        return user;
    }
}