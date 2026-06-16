using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.Repositories;
using NMTales.Backend.Repositories.Location;
using NMTales.Backend.Services.Location;
using NMTales.Backend.Services.Player;
using Microsoft.Extensions.Logging;

namespace NMTales.Backend.Controllers;

/// <summary>
/// API Controller responsible for serving location pack files to authenticated users.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize] 
public class LocationController : ControllerBase
{
    private readonly IPlayerService _playerService;
    private readonly ILocationService _locationService;
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<LocationController> _logger;

    /// <summary>
    /// Initializes the controller with the necessary services and environment info.
    /// </summary>
    public LocationController(IPlayerService playerService, ILocationService locationService, IWebHostEnvironment env, ILogger<LocationController> logger)
    {
       _playerService = playerService;
       _locationService = locationService;
       _env = env;
       _logger = logger;
    }

    /// <summary>
    /// Retrieves the resource pack for a specific location if the user meets the requirements.
    /// </summary>
    /// <param name="locationName">The name of the requested location.</param>
    /// <returns>The .pck file stream, or an appropriate error status.</returns>
    [HttpGet("{locationName}/pack")]
    public async Task<IActionResult> GetLocationPack(string locationName)
    {
       var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
       if (!int.TryParse(userIdValue, out var userId))
       {
          return Unauthorized();
       }

       var user = await _playerService.GetPlayerAsync(userId);
       if (user == null)
       {
          return NotFound("User not found");
       }

       var location = await _locationService.GetLocationByNameAsync(locationName);
       if (location == null)
       {
           return NotFound("Location not configured in database");
       }
       
       _logger.LogInformation("Location check: Id={LocationId}, Name={LocationName}, Description={LocationDescription}, RequiredLevel={RequiredLevel}, Subject={Subject}",
          location.Id, location.Name, location.Description, location.RequiredLevel, location.Subject);
       
       // Anti-cheat access check: ensure player meets level requirements
       if (user.Level < location.RequiredLevel)
       {
           return Forbid("You do not have access to this location. Level too low.");
       }

       var filePath = Path.Combine(_env.ContentRootPath, "Packs", $"{locationName}.pck");

       if (!System.IO.File.Exists(filePath))
       {
          return NotFound("Location pack file not found on server");
       }

       // Stream the file directly from disk to conserve memory
       return PhysicalFile(filePath, "application/octet-stream", $"{locationName}.pck");
    }
}
