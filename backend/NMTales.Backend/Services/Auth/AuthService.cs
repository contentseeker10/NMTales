using NMTales.Backend.DTO;
using NMTales.Backend.Models;
using NMTales.Backend.Repositories.User;

namespace NMTales.Backend.Services.Auth;

public class AuthService : IAuthService
{
    private readonly IUserRepository _userRepo;
    private readonly JwtService _jwtService;

    public AuthService(IUserRepository userRepo, JwtService jwtService)
    {
        _userRepo = userRepo;
        _jwtService = jwtService;
    }

    public async Task<AuthResponseDto?> RegisterAsync(RegisterDto dto)
    {
        // 1. Check if username is already taken
        if (await _userRepo.UsernameExistsAsync(dto.Username))
        {
            return null; // The controller will handle returning the 400 BadRequest
        }

        // 2. Create the user
        var user = new Models.User
        {
            Username = dto.Username,
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            XP = 0,
            Level = 1,
            CurrentLocation = "main",
            CurrentPositionX = 0.0,
            CurrentPositionY = 0.0
        };

        // 3. Save to database
        await _userRepo.AddAsync(user);
        await _userRepo.SaveChangesAsync();

        // 4. Return success response
        return new AuthResponseDto
        {
            Message = "User created",
            Token = _jwtService.GenerateToken(user),
            User = UserDto.FromModel(user)
        };
    }

    public async Task<AuthResponseDto?> LoginAsync(LoginDto dto)
    {
        // 1. Fetch user by username
        var user = await _userRepo.GetByUsernameAsync(dto.Username);

        // 2. Verify existence and password
        if (user == null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.Password))
        {
            return null;
        }

        // 3. Return success response
        return new AuthResponseDto
        {
            Message = "Login successful",
            Token = _jwtService.GenerateToken(user),
            User = UserDto.FromModel(user)
        };
    }

    public async Task<UserDto?> GetUserByIdAsync(int userId)
    {
        var user = await _userRepo.GetByIdAsync(userId);
        return user != null ? UserDto.FromModel(user) : null;
    }
}