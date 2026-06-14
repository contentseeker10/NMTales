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

[ApiController]
[Route("api/[controller]")]
[Authorize] // Защищаем весь контроллер. Запросы без валидного JWT получат 401 Unauthorized
public class LocationController : ControllerBase
{
	//private readonly ApplicationDbContext _context;
	private readonly IPlayerService _playerService;
	private readonly ILocationService _locationService;
	private readonly IWebHostEnvironment _env;
	private readonly ILogger<LocationController> _logger;

	// Внедряем контекст БД и окружение (чтобы узнать путь к папке Packs) через конструктор
	public LocationController(IPlayerService playerService, ILocationService locationService, IWebHostEnvironment env, ILogger<LocationController> logger)
	{
		_playerService = playerService;
		_locationService = locationService;
		_env = env;
		_logger = logger;
	}

	[HttpGet("{locationName}/pack")]
	public async Task<IActionResult> GetLocationPack(string locationName)
	{
		// 1. Получаем ID пользователя из JWT-токена
		var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
		if (!int.TryParse(userIdValue, out var userId))
		{
			return Unauthorized();
		}

		// 2. Ищем пользователя в БД
		var user = await _playerService.GetPlayerAsync(userId);
		if (user == null)
		{
			return NotFound("User not found");
		}

		// 3. Ищем запрашиваемую локацию в БД (чтобы проверить требования)
		var location = await _locationService.GetLocationByNameAsync(locationName);
		if (location == null)
		{
		    return NotFound("Location not configured in database");
		}
		
		_logger.LogInformation("Location check: Id={LocationId}, Name={LocationName}, Description={LocationDescription}, RequiredLevel={RequiredLevel}, Subject={Subject}",
			location.Id, location.Name, location.Description, location.RequiredLevel, location.Subject);
		
		// 4. ПРОВЕРКА ДОСТУПА (Бизнес-логика против читерства)
		// Проверяем, хватает ли у игрока уровня для входа на эту локацию
		if (user.Level < location.RequiredLevel)
		{
		    return Forbid("You do not have access to this location. Level too low.");
		}

		// 5. Определение пути к файлу на сервере
		// Собираем абсолютный путь к Packs/имя_локации.pck
		var filePath = Path.Combine(_env.ContentRootPath, "Packs", $"{locationName}.pck");

		if (!System.IO.File.Exists(filePath))
		{
			return NotFound("Location pack file not found on server");
		}

		// 6. Отдача файла клиенту (Senior-practice)
		// Вместо вычитывания всего файла в оперативку (ReadAllBytes),
		// используем PhysicalFile, который эффективно стримит файл с диска
		return PhysicalFile(filePath, "application/octet-stream", $"{locationName}.pck");
	}
}
