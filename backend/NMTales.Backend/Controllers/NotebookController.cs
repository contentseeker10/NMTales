using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Models;

namespace NMTales.Backend.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotebookController : ControllerBase
{
    private const int MaxPagesPerUser = 10;
    private const string PageLimitMessage = "Reached the maximum number of pages (max. 10)";

    private readonly ApplicationDbContext _context;
    private readonly IValidator<CreateNotebookPageDto> _createValidator;
    private readonly IValidator<UpdateNotebookPageDto> _updateValidator;

    public NotebookController(
        ApplicationDbContext context,
        IValidator<CreateNotebookPageDto> createValidator,
        IValidator<UpdateNotebookPageDto> updateValidator)
    {
        _context = context;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var pages = await _context.NotebookPages
            .Where(p => p.UserId == userId)
            .OrderBy(p => p.CreatedAt)
            .ToListAsync();

        return Ok(pages.Select(NotebookPageDto.FromModel));
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateNotebookPageDto dto)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var validationResult = await _createValidator.ValidateAsync(dto);
        if (!validationResult.IsValid)
        {
            return BadRequest(validationResult.Errors);
        }

        var pageCount = await _context.NotebookPages.CountAsync(p => p.UserId == userId);
        if (pageCount >= MaxPagesPerUser)
        {
            return BadRequest(PageLimitMessage);
        }

        var page = new NotebookPage
        {
            UserId = userId,
            Title = dto.Title,
            Content = string.Empty,
            CreatedAt = DateTime.UtcNow
        };

        _context.NotebookPages.Add(page);
        await _context.SaveChangesAsync();

        return Ok(NotebookPageDto.FromModel(page));
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateNotebookPageDto dto)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var validationResult = await _updateValidator.ValidateAsync(dto);
        if (!validationResult.IsValid)
        {
            return BadRequest(validationResult.Errors);
        }

        var page = await _context.NotebookPages
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (page == null)
        {
            return NotFound();
        }

        page.Title = dto.Title;
        page.Content = dto.Content;

        await _context.SaveChangesAsync();

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var page = await _context.NotebookPages
            .FirstOrDefaultAsync(p => p.Id == id && p.UserId == userId);

        if (page == null)
        {
            return NotFound();
        }

        _context.NotebookPages.Remove(page);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private bool TryGetUserId(out int userId)
    {
        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(userIdValue, out userId);
    }
}
