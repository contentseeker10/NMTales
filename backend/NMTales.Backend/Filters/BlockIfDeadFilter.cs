using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using NMTales.Backend.Data;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace NMTales.Backend.Filters
{
    public class BlockIfDeadFilter : IAsyncActionFilter
    {
        private readonly ApplicationDbContext _context;

        public BlockIfDeadFilter(ApplicationDbContext context)
        {
            _context = context;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var userPrincipal = context.HttpContext.User;
            if (userPrincipal.Identity?.IsAuthenticated == true)
            {
                var userIdValue = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                if (int.TryParse(userIdValue, out var userId))
                {
                    var hasAllowDeadAttribute = context.ActionDescriptor.EndpointMetadata
                        .Any(em => em is AllowDeadPlayerAttribute);

                    if (!hasAllowDeadAttribute)
                    {
                        var user = await _context.Users.FindAsync(userId);
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
