using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Filters;
using NMTales.Backend.Models;
using NMTales.Backend.Services;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

namespace NMTales.Backend.Controllers
{
    [ApiController]
    [Route("api/combat")]
    [Authorize]
    public class PlayerCombatController : ControllerBase
    {
        private readonly ApplicationDbContext _context;
        private readonly IAchievementService _achievementService;

        public PlayerCombatController(ApplicationDbContext context, IAchievementService achievementService)
        {
            _context = context;
            _achievementService = achievementService;
        }

        [HttpPost("attack")]
        public async Task<IActionResult> Attack()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("User not found");

            if (user.IsDead)
            {
                return BadRequest(new { error = "Player is dead." });
            }

            var now = DateTime.UtcNow;
            if (user.LastAttackTimeUtc.HasValue && 
                (now - user.LastAttackTimeUtc.Value).TotalSeconds < 2.86)
            {
                return BadRequest(new { error = "Attack is on cooldown." });
            }

            user.LastAttackTimeUtc = now;
            await _context.SaveChangesAsync();
            return Ok(new { success = true });
        }

        [HttpPost("damage")]
        [AllowDeadPlayer]
        public async Task<IActionResult> RegisterDamage([FromBody] RegisterDamageRequestDto dto)
        {
            if (dto == null || dto.Amount < 0)
            {
                return BadRequest("Invalid damage amount.");
            }

            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("User not found");

            if (user.IsDead)
            {
                return Ok(new { currentHp = user.CurrentHp, isDead = user.IsDead });
            }

            user.CurrentHp -= dto.Amount;
            if (user.CurrentHp <= 0)
            {
                user.CurrentHp = 0;
                user.IsDead = true;

                var stats = await _context.PlayerStats.FirstOrDefaultAsync(ps => ps.UserId == userId);
                if (stats == null)
                {
                    stats = new PlayerStats { UserId = userId };
                    _context.PlayerStats.Add(stats);
                }
                stats.DeathsCount++;
                stats.HasDied = true;
                await _context.SaveChangesAsync();

                await _achievementService.EvaluateAndUnlockAchievementsAsync(userId);
            }
            else
            {
                await _context.SaveChangesAsync();
            }

            return Ok(new { currentHp = user.CurrentHp, isDead = user.IsDead });
        }

        [HttpPost("heal")]
        public async Task<IActionResult> Heal([FromBody] HealPlayerRequestDto dto)
        {
            if (dto == null)
            {
                return BadRequest("Invalid healing payload.");
            }

            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("User not found");

            if (user.IsDead)
            {
                return BadRequest(new { error = "Player is dead." });
            }

            double dx = user.CurrentPositionX - dto.PositionX;
            double dy = user.CurrentPositionY - dto.PositionY;
            double distance = Math.Sqrt(dx * dx + dy * dy);

            if (distance > 120.0)
            {
                return BadRequest("Too far from the healing item.");
            }

            user.CurrentHp = Math.Min(user.MaxHp, user.CurrentHp + 10);
            await _context.SaveChangesAsync();

            return Ok(new { currentHp = user.CurrentHp });
        }

        [HttpPost("respawn")]
        [AllowDeadPlayer]
        public async Task<IActionResult> Respawn()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound("User not found");

            user.IsDead = false;
            user.CurrentHp = 20;
            user.CurrentPositionX = 0.0;
            user.CurrentPositionY = 0.0;
            await _context.SaveChangesAsync();

            return Ok(new
            {
                currentHp = user.CurrentHp,
                isDead = user.IsDead,
                positionX = user.CurrentPositionX,
                positionY = user.CurrentPositionY
            });
        }

        private bool TryGetUserId(out int userId)
        {
            var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(userIdValue, out userId);
        }
    }
}
