using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Models;
using NMTales.Backend.Services;

namespace NMTales.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly JwtService _jwtService;
    private readonly IValidator<RegisterDto> _registerValidator;
    private readonly IValidator<LoginDto> _loginValidator;

    public AuthController(ApplicationDbContext context, JwtService jwtService, IValidator<RegisterDto> registerValidator, IValidator<LoginDto> loginValidator)
    {
        _context = context;
        _jwtService = jwtService;
        _registerValidator = registerValidator;
        _loginValidator = loginValidator;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        var validationResult = await _registerValidator.ValidateAsync(dto);

        if (!validationResult.IsValid)
            return BadRequest(AuthValidationErrorResponseDto.FromValidationResult(validationResult));
        
        var user = new User
        {
            Username = dto.Username,
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password)
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();

        return Ok(new AuthResponseDto
        {
            Message = "User created",
            Token = _jwtService.GenerateToken(user),
            User = UserDto.FromModel(user)
        });
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var validationResult = await _loginValidator.ValidateAsync(dto);
        
        if (!validationResult.IsValid)
            return BadRequest(AuthValidationErrorResponseDto.FromValidationResult(validationResult));
        
        var user = await _context.Users.FirstOrDefaultAsync(x => x.Username == dto.Username);

        if (user is null || !BCrypt.Net.BCrypt.Verify(dto.Password, user.Password))
        {
            return Unauthorized("Invalid username or password");
        }

        return Ok(new AuthResponseDto
        {
            Message = "Login successful",
            Token = _jwtService.GenerateToken(user),
            User = UserDto.FromModel(user)
        });
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        var user = await _context.Users.FindAsync(userId);

        if (user is null)
        {
            return NotFound();
        }

        return Ok(UserDto.FromModel(user));
    }
}
