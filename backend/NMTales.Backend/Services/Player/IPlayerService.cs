using NMTales.Backend.Models;

namespace NMTales.Backend.Services.Player;

public interface IPlayerService
{
    Task<Models.User?> GetPlayerAsync(int userId);
    Task<Models.User?> UpdateLocationAsync(int userId, string location, double x, double y);
}