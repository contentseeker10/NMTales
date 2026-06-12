using NMTales.Backend.Models;

namespace NMTales.Backend.Services.Player;

public interface IPlayerService
{
    Task<User?> GetPlayerAsync(int userId);
    Task<User?> UpdateLocationAsync(int userId, string location, double x, double y);
}