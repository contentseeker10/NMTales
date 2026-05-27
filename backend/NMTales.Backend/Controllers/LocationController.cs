using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;

namespace NMTales.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // Защищаем весь контроллер. Запросы без валидного JWT получат 401 Unauthorized
public class LocationController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly IWebHostEnvironment _env;

    // Внедряем контекст БД и окружение (чтобы узнать путь к папке Packs) через конструктор
    public LocationController(ApplicationDbContext context, IWebHostEnvironment env)
    {
        _context = context;
        _env = env;
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
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
        {
            return NotFound("User not found");
        }

        // // 3. Ищем запрашиваемую локацию в БД (чтобы проверить требования)
        // var location = await _context.Locations
        //     .FirstOrDefaultAsync(l => l.Name.ToLower() == locationName.ToLower());
            
        // if (location == null)
        // {
        //     return NotFound("Location not configured in database");
        // }

        // // 4. ПРОВЕРКА ДОСТУПА (Бизнес-логика против читерства)
        // // Проверяем, хватает ли у игрока уровня для входа на эту локацию
        // if (user.Level < location.RequiredLevel)
        // {
        //     return Forbid("You do not have access to this location. Level too low.");
        // }

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