using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using NMTales.Backend.Data;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace NMTales.Backend.Filters
{
    /// <summary>
    /// An action filter that intercepts API requests to ensure a player is alive before allowing the action to proceed.
    /// </summary>
    public class BlockIfDeadFilter : IAsyncActionFilter
    {
        private readonly ApplicationDbContext _context;
        
        public BlockIfDeadFilter(ApplicationDbContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Executes before the requested controller action runs.
        /// </summary>
        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var userPrincipal = context.HttpContext.User;
            if (userPrincipal.Identity?.IsAuthenticated == true)
            {
                var userIdValue = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (int.TryParse(userIdValue, out var userId))
                {
                    // Check if the target endpoint opts out of this restriction (e.g., respawn endpoints)
                    var hasAllowDeadAttribute = context.ActionDescriptor.EndpointMetadata
                        .Any(em => em is AllowDeadPlayerAttribute);

                    if (!hasAllowDeadAttribute)
                    {
                        var user = await _context.Users.FindAsync(userId);
                        
                        // Short-circuit the request if the player is dead and the action isn't whitelisted
                        if (user != null && user.IsDead)
                        {
                            context.Result = new BadRequestObjectResult(new { error = "Player is dead. Please respawn." });
                            return;
                        }
                    }
                }
            }

            await next();
        }
    }
}
