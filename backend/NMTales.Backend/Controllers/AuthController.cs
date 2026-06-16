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

using NMTales.Backend.Filters;

namespace NMTales.Backend.Controllers;

/// <summary>
/// API Controller responsible for managing user authentication, registration, and session state.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[AllowDeadPlayer]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly JwtService _jwtService;
    private readonly IValidator<RegisterDto> _registerValidator;
    private readonly IValidator<LoginDto> _loginValidator;

    /// <summary>
    /// Initializes the controller with necessary authentication services and validators.
    /// </summary>
    public AuthController(IAuthService authService, JwtService jwtService, IValidator<RegisterDto> registerValidator, IValidator<LoginDto> loginValidator)
    {
        _authService = authService;
        _jwtService = jwtService;
        _registerValidator = registerValidator;
        _loginValidator = loginValidator;
    }

    /// <summary>
    /// Registers a new user account.
    /// </summary>
    /// <returns>The created user details and auth token, or a Bad Request if validation fails or the username is taken.</returns>
    [HttpPost("register")]
    public async Task<IActionResult> Register(RegisterDto dto)
    {
        // Check if the incoming registration payload meets all validation rules
        var validationResult = await _registerValidator.ValidateAsync(dto);
        if (!validationResult.IsValid)
            return BadRequest(AuthValidationErrorResponseDto.FromValidationResult(validationResult));
        
        // Attempt to register the user in the database
        var result = await _authService.RegisterAsync(dto);

        // A null result indicates the username is already in use
        if (result == null)
        {
            return BadRequest(new { Message = "Username is already taken." });
        }

        return Ok(result);
    }

    /// <summary>
    /// Authenticates a user and issues a JWT token for subsequent requests.
    /// </summary>
    /// <returns>An authentication token on success, or Unauthorized if the credentials are invalid.</returns>
    [HttpPost("login")]
    public async Task<IActionResult> Login(LoginDto dto)
    {
        // Check if the incoming login payload meets all validation rules
        var validationResult = await _loginValidator.ValidateAsync(dto);
        if (!validationResult.IsValid)
            return BadRequest(AuthValidationErrorResponseDto.FromValidationResult(validationResult));
        
        // Attempt to authenticate against the stored credentials
        var result = await _authService.LoginAsync(dto);

        // A null result indicates authentication failure (wrong username or password)
        if (result == null)
        {
            return Unauthorized(new { Message = "Invalid username or password" });
        }

        return Ok(result);
    }

    /// <summary>
    /// Retrieves the profile data of the currently authenticated user.
    /// </summary>
    /// <returns>The user's profile details, or Not Found if the user record no longer exists.</returns>
    [Authorize]
    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        // Extract the user ID from the active JWT claims
        var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        // Fetch the up-to-date user information from the database
        var userDto = await _authService.GetUserByIdAsync(userId);

        if (userDto == null)
        {
            return NotFound();
        }

        return Ok(userDto);
    }
}
