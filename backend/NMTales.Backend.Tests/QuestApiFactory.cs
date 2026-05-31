using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using NMTales.Backend.Data;

namespace NMTales.Backend.Tests;

/// <summary>
/// Boots the real backend in-process for integration tests, but swaps the shared
/// in-memory database for a uniquely named one so each factory instance is isolated.
/// </summary>
public class QuestApiFactory : WebApplicationFactory<NMTales.Backend.Program>
{
    private readonly string _dbName = Guid.NewGuid().ToString();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // Use the real backend project directory as the content root so appsettings.json
        // (the JWT signing key) and the closed Quests/ configuration folder are present
        // exactly as in production. The signing key must be the same one Program.cs reads
        // when building the JWT validation parameters, so it is intentionally not overridden.
        var contentRoot = Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "NMTales.Backend"));
        builder.UseContentRoot(contentRoot);

        builder.ConfigureServices(services =>
        {
            var toRemove = services
                .Where(d => d.ServiceType == typeof(DbContextOptions<ApplicationDbContext>)
                            || d.ServiceType == typeof(ApplicationDbContext))
                .ToList();
            foreach (var descriptor in toRemove)
            {
                services.Remove(descriptor);
            }

            services.AddDbContext<ApplicationDbContext>(options =>
                options.UseInMemoryDatabase(_dbName));
        });
    }
}
