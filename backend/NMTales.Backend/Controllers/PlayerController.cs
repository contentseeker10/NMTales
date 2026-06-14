using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Services.Player;

namespace NMTales.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PlayerController : ControllerBase
{
    private readonly IPlayerService _playerService;
    private readonly IValidator<UpdatePlayerLocationDto> _validator;

    public PlayerController(IPlayerService playerService, IValidator<UpdatePlayerLocationDto> validator)
    {
        _playerService = playerService;
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

        var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        var user = await _playerService.UpdateLocationAsync(
            userId, 
            dto.CurrentLocation, 
            dto.CurrentPositionX, 
            dto.CurrentPositionY);

        if (user == null)
        {
            return NotFound("User not found");
        }

        return Ok(UserDto.FromModel(user));
    }

    [HttpGet("location")]
    public async Task<IActionResult> GetLocation()
    {
        var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        var user = await _playerService.GetPlayerAsync(userId);
        if (user == null)
        {
            return NotFound("User not found");
        }

        // Using an anonymous object initializer to return just the location data
        return Ok(new
        {
            user.CurrentLocation,
            user.CurrentPositionX,
            user.CurrentPositionY
        });
    }
}
