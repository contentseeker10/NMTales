using FluentValidation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Models;
using NMTales.Backend.Services;

namespace NMTales.Backend.Controllers;

/// <summary>
/// API Controller for managing user notebook pages.
/// </summary>
/// <remarks>
/// All endpoints require an authenticated user. Users are limited to a maximum of 10 pages.
/// </remarks>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class NotebookController : ControllerBase
{
    private const int MaxPagesPerUser = 10;
    private const string PageLimitMessage = "Reached the maximum number of pages (max. 10)";

    private readonly INotebookService _notebookService;
    private readonly IValidator<CreateNotebookPageDto> _createValidator;
    private readonly IValidator<UpdateNotebookPageDto> _updateValidator;

    /// <summary>
    /// Initializes the controller with required services and validators.
    /// </summary>
    public NotebookController(
        INotebookService notebookService,
        IValidator<CreateNotebookPageDto> createValidator,
        IValidator<UpdateNotebookPageDto> updateValidator)
    {
        _notebookService = notebookService;
        _createValidator = createValidator;
        _updateValidator = updateValidator;
    }

    /// <summary>
    /// Retrieves all notebook pages for the authenticated user.
    /// </summary>
    /// <returns>A collection of the user's notebook pages.</returns>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        // Ensure we have a valid logged-in user
        if (!TryGetUserId(out var userId)) return Unauthorized();
        
        // Fetch pages and map them to DTOs for the response
        var pages = await _notebookService.GetAllPagesAsync(userId);
        return Ok(pages.Select(NotebookPageDto.FromModel));
    }

    /// <summary>
    /// Creates a new notebook page.
    /// </summary>
    /// <returns>The created page, or a Bad Request if validation fails or the user limit is reached.</returns>
    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateNotebookPageDto dto)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        // Check if the incoming payload is valid before proceeding
        var validationResult = await _createValidator.ValidateAsync(dto);
        if (!validationResult.IsValid)
        {
            return BadRequest(validationResult.Errors);
        }

        // Attempt to create the page; returns null if the user exceeded their limit
        var page = await _notebookService.CreatePageAsync(userId, dto.Title);
        if (page == null)
        {
            return BadRequest(PageLimitMessage);
        }

        return Ok(NotebookPageDto.FromModel(page));
    }

    /// <summary>
    /// Updates an existing notebook page's title and content.
    /// </summary>
    /// <returns>No Content on success, or Not Found if the page doesn't exist or access is denied.</returns>
    [HttpPut("{id}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateNotebookPageDto dto)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        // Validate the incoming payload
        var validationResult = await _updateValidator.ValidateAsync(dto);
        if (!validationResult.IsValid)
        {
            return BadRequest(validationResult.Errors);
        }

        try
        {
            // Returns false if the page doesn't exist
            var pageUpdated = await _notebookService.UpdatePageAsync(id, userId, dto.Title, dto.Content);
            if (pageUpdated == false)
                return NotFound();

            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            // Catch unauthorized attempts to modify someone else's page
            return NotFound();
        }
    }

    /// <summary>
    /// Deletes a specific notebook page.
    /// </summary>
    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(int id)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        // Attempt deletion; returns false if the page doesn't exist or isn't owned by the user
        var pageDeleted = await _notebookService.DeletePageAsync(id, userId);
        if (pageDeleted == false)
            return NotFound();
        
        return NoContent();
    }

    /// <summary>
    /// Extracts the user ID from the current authentication claims.
    /// </summary>
    /// <returns>True if a valid user ID was found; otherwise, false.</returns>
    private bool TryGetUserId(out int userId)
    {
        // Look for the NameIdentifier claim typically set by JWT auth
        var userIdValue = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(userIdValue, out userId);
    }
}
