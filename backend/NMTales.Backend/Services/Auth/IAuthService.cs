using NMTales.Backend.DTO;

namespace NMTales.Backend.Services.Auth;

public interface IAuthService
{
    Task<AuthResponseDto?> RegisterAsync(RegisterDto dto);
    Task<AuthResponseDto?> LoginAsync(LoginDto dto);
    Task<UserDto?> GetUserByIdAsync(int userId);
}