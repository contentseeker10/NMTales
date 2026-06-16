using System.Security.Claims;
using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Services.Player;

namespace NMTales.Backend.Controllers;

/// <summary>
/// API Controller for tracking and managing the player's physical location within the game world.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class PlayerController : ControllerBase
{
    private readonly IPlayerService _playerService;
    private readonly IValidator<UpdatePlayerLocationDto> _validator;

    /// <summary>
    /// Initializes the controller with the necessary player service and input validator.
    /// </summary>
    public PlayerController(IPlayerService playerService, IValidator<UpdatePlayerLocationDto> validator)
    {
        _playerService = playerService;
        _validator = validator;
    }

    /// <summary>
    /// Updates the current coordinates and active map location for the authenticated player.
    /// </summary>
    /// <param name="dto">The new location data, including map name and X/Y coordinates.</param>
    /// <returns>The updated player profile, or a BadRequest if validation fails.</returns>
    [HttpPost("location")]
    public async Task<IActionResult> UpdateLocation([FromBody] UpdatePlayerLocationDto dto)
    {
        // Ensure the incoming coordinates and map data meet format requirements
        var validationResult = await _validator.ValidateAsync(dto);
        if (!validationResult.IsValid)
        {
            return BadRequest(validationResult.Errors);
        }

        // Extract the user ID from the active JWT claims
        var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!int.TryParse(userIdValue, out var userId))
        {
            return Unauthorized();
        }

        // Persist the new location state
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

    /// <summary>
    /// Retrieves the last known coordinates and active map location of the authenticated player.
    /// </summary>
    /// <returns>An object containing the current map name and X/Y position.</returns>
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

        // Using an anonymous object initializer to return just the essential location data
        return Ok(new
        {
            user.CurrentLocation,
            user.CurrentPositionX,
            user.CurrentPositionY
        });
    }
}
