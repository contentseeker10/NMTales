using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;

namespace NMTales.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PlayerController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IValidator<UpdatePlayerLocationDto> _validator;

    public PlayerController(ApplicationDbContext context, IValidator<UpdatePlayerLocationDto> validator)
    {
        _context = context;
        _validator = validator;
    }

    [HttpPost("location")]
    public async Task<IActionResult> UpdateLocation([FromBody] UpdatePlayerLocationDto dto)
    {
        var validationResult = await _validator.ValidateAsync(dto);
        if (!validationResult.IsValid)
        {
            return BadRequest(validationResult.Errors);
        }

        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound("User not found");
        }

        user.CurrentLocation = dto.CurrentLocation;
        user.CurrentPositionX = dto.CurrentPositionX;
        user.CurrentPositionY = dto.CurrentPositionY;

        await _context.SaveChangesAsync();

        return Ok(UserDto.FromModel(user));
    }

    [HttpGet("location")]
    public async Task<IActionResult> GetLocation()
    {
        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound("User not found");
        }

        return Ok(new
        {
            user.CurrentLocation,
            user.CurrentPositionX,
            user.CurrentPositionY
        });
    }
}
