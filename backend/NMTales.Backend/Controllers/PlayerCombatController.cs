using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Filters;
using NMTales.Backend.Models;
using NMTales.Backend.Services;
using NMTales.Backend.Repositories.User;
using NMTales.Backend.Repositories.PlayerStats;
using System;
using System.Security.Claims;
using System.Threading.Tasks;

namespace NMTales.Backend.Controllers
{
    /// <summary>
    /// API Controller for managing player combat mechanics, including attacks, damage handling, healing, and respawns.
    /// </summary>
    [ApiController]
    [Route("api/combat")]
    [Authorize]
    public class PlayerCombatController : ControllerBase
    {
        private readonly IUserRepository _userRepository;
        private readonly IPlayerStatsRepository _playerStatsRepository;
        private readonly IAchievementService _achievementService;

        /// <summary>
        /// Initializes the controller with necessary repositories and services.
        /// </summary>
        public PlayerCombatController(
            IUserRepository userRepository, 
            IPlayerStatsRepository playerStatsRepository,
            IAchievementService achievementService)
        {
            _userRepository = userRepository;
            _playerStatsRepository = playerStatsRepository;
            _achievementService = achievementService;
        }

        /// <summary>
        /// Registers a player's attack action and validates the server-side attack cooldown.
        /// </summary>
        /// <returns>A success status if the attack is permitted, or a BadRequest if the player is dead or on cooldown.</returns>
        [HttpPost("attack")]
        public async Task<IActionResult> Attack()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null) return NotFound("User not found");

            if (user.IsDead)
            {
                return BadRequest(new { error = "Player is dead." });
            }

            // Enforce a hard server-side cooldown of ~2.86 seconds between attacks
            var now = DateTime.UtcNow;
            if (user.LastAttackTimeUtc.HasValue && 
                (now - user.LastAttackTimeUtc.Value).TotalSeconds < 2.86)
            {
                return BadRequest(new { error = "Attack is on cooldown." });
            }

            user.LastAttackTimeUtc = now;
            await _userRepository.SaveChangesAsync();
            return Ok(new { success = true });
        }

        /// <summary>
        /// Applies incoming damage to a player and manages the transition to a death state if health drops to zero.
        /// </summary>
        /// <param name="dto">Data containing the amount of damage to apply.</param>
        /// <returns>The player's current health and death status.</returns>
        [HttpPost("damage")]
        [AllowDeadPlayer]
        public async Task<IActionResult> RegisterDamage([FromBody] RegisterDamageRequestDto dto)
        {
            if (dto == null || dto.Amount < 0)
            {
                return BadRequest("Invalid damage amount.");
            }

            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null) return NotFound("User not found");

            if (user.IsDead)
            {
                return Ok(new { currentHp = user.CurrentHp, isDead = user.IsDead });
            }

            user.CurrentHp -= dto.Amount;
            
            // Handle fatal damage logic
            if (user.CurrentHp <= 0)
            {
                user.CurrentHp = 0;
                user.IsDead = true;

                // Ensure stats exist before recording the death
                var stats = await _playerStatsRepository.GetByUserIdAsync(userId);
                if (stats == null)
                {
                    stats = new PlayerStats { UserId = userId };
                    await _playerStatsRepository.AddAsync(stats);
                }
                stats.DeathsCount++;
                stats.HasDied = true;
                await _playerStatsRepository.SaveChangesAsync();

                // Check if dying triggered any specific achievements (e.g., first death)
                await _achievementService.EvaluateAndUnlockAchievementsAsync(userId);
            }
            else
            {
                await _userRepository.SaveChangesAsync();
            }

            return Ok(new { currentHp = user.CurrentHp, isDead = user.IsDead });
        }

        /// <summary>
        /// Restores a player's health, provided they are within physical range of the healing source.
        /// </summary>
        /// <param name="dto">Data containing the coordinates of the healing source.</param>
        /// <returns>The player's updated health status.</returns>
        [HttpPost("heal")]
        public async Task<IActionResult> Heal([FromBody] HealPlayerRequestDto dto)
        {
            if (dto == null)
            {
                return BadRequest("Invalid healing payload.");
            }

            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null) return NotFound("User not found");

            if (user.IsDead)
            {
                return BadRequest(new { error = "Player is dead." });
            }

            // Calculate Euclidean distance to prevent remote healing exploits
            double dx = user.CurrentPositionX - dto.PositionX;
            double dy = user.CurrentPositionY - dto.PositionY;
            double distance = Math.Sqrt(dx * dx + dy * dy);

            if (distance > 120.0)
            {
                return BadRequest("Too far from the healing item.");
            }

            // Restore a flat 10 HP, capping at the player's maximum health
            user.CurrentHp = Math.Min(user.MaxHp, user.CurrentHp + 10);
            await _userRepository.SaveChangesAsync();

            return Ok(new { currentHp = user.CurrentHp });
        }

        /// <summary>
        /// Revives a dead player, resetting their health and teleporting them to the default spawn coordinates.
        /// </summary>
        /// <returns>The player's new health, status, and position coordinates.</returns>
        [HttpPost("respawn")]
        [AllowDeadPlayer]
        public async Task<IActionResult> Respawn()
        {
            if (!TryGetUserId(out var userId)) return Unauthorized();

            var user = await _userRepository.GetByIdAsync(userId);
            if (user == null) return NotFound("User not found");

            user.IsDead = false;
            user.CurrentHp = 20; // Base respawn health
            user.CurrentPositionX = 0.0;
            user.CurrentPositionY = 0.0;
            await _userRepository.SaveChangesAsync();

            return Ok(new
            {
                currentHp = user.CurrentHp,
                isDead = user.IsDead,
                positionX = user.CurrentPositionX,
                positionY = user.CurrentPositionY
            });
        }

        /// <summary>
        /// Extracts the user ID from the active JWT claims.
        /// </summary>
        private bool TryGetUserId(out int userId)
        {
            var userIdValue = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(userIdValue, out userId);
        }
    }
}
