using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Models;
using NMTales.Backend.Services;
using NMTales.Backend.Services.Auth;

namespace NMTales.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    //private readonly ApplicationDbContext _context;
    private readonly IAuthService _authService;
    private readonly JwtService _jwtService;
    private readonly IValidator<RegisterDto> _registerValidator;
    private readonly IValidator<LoginDto> _loginValidator;

    public AuthController(IAuthService authService, JwtService jwtService, IValidator<RegisterDto> registerValidator, IValidator<LoginDto> loginValidator)
    {
        _authService = authService;
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
        
        var result = await _authService.RegisterAsync(dto);

        if (result == null)
        {
            return BadRequest(new { Message = "Username is already taken." });
        }

        return Ok(result);
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        var validationResult = await _loginValidator.ValidateAsync(dto);
        if (!validationResult.IsValid)
            return BadRequest(AuthValidationErrorResponseDto.FromValidationResult(validationResult));
        
        var result = await _authService.LoginAsync(dto);

        if (result == null)
        {
            return Unauthorized(new { Message = "Invalid username or password" });
        }

        return Ok(result);
    }

    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        var userDto = await _authService.GetUserByIdAsync(userId);

        if (userDto == null)
        {
            return NotFound();
        }

        return Ok(userDto);
    }
}
