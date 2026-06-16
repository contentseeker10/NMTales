using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using NMTales.Backend.Data;
using System;
using System.IO;
using System.Linq;

namespace NMTales.Backend.Tests;

/// <summary>
/// Boots the real backend in-process for integration tests, but swaps the shared
/// in-memory database for a uniquely named one so each factory instance is isolated.
/// Dynamically creates isolated temp directories and test configurations to avoid race conditions.
/// </summary>
public class QuestApiFactory : WebApplicationFactory<NMTales.Backend.Program>
{
    private readonly string _dbName = Guid.NewGuid().ToString();
    private string? _tempContentRoot;

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        // First get the real content root
        var realContentRoot = Path.GetFullPath(
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", "NMTales.Backend"));
        
        // Create a unique temporary directory for this factory instance to prevent races
        _tempContentRoot = Path.Combine(Path.GetTempPath(), "NMTales_Test_" + Guid.NewGuid());
        Directory.CreateDirectory(_tempContentRoot);

        // Copy appsettings.json if it exists
        var realAppSettings = Path.Combine(realContentRoot, "appsettings.json");
        if (File.Exists(realAppSettings))
        {
            File.Copy(realAppSettings, Path.Combine(_tempContentRoot, "appsettings.json"));
        }

        // Copy appsettings.Development.json if it exists
        var realDevSettings = Path.Combine(realContentRoot, "appsettings.Development.json");
        if (File.Exists(realDevSettings))
        {
            File.Copy(realDevSettings, Path.Combine(_tempContentRoot, "appsettings.Development.json"));
        }

        // Copy the real Quests folder too so all game quests are also available if needed
        var realQuestsPath = Path.Combine(realContentRoot, "Quests");
        if (Directory.Exists(realQuestsPath))
        {
            CopyDirectory(realQuestsPath, Path.Combine(_tempContentRoot, "Quests"));
        }

        // Add test/mock quest configurations
        var npcTestPath = Path.Combine(_tempContentRoot, "Quests", "npc_test");
        var npcQuestPath = Path.Combine(_tempContentRoot, "Quests", "npc_quest");

        Directory.CreateDirectory(npcTestPath);
        Directory.CreateDirectory(npcQuestPath);

        File.WriteAllText(Path.Combine(npcTestPath, "quest_1.json"), @"{
            ""id"": ""quest_1"",
            ""repeatable"": false,
            ""objective"": {
                ""type"": ""talk_npc"",
                ""target"": ""npc_quest"",
                ""required_amount"": 1
            },
            ""rewards"": {
                ""xp"": 100
            }
        }");

        File.WriteAllText(Path.Combine(npcTestPath, "quest_2.json"), @"{
            ""id"": ""quest_2"",
            ""repeatable"": false,
            ""objective"": {
                ""type"": ""talk_npc"",
                ""target"": ""npc_quest"",
                ""required_amount"": 1
            },
            ""rewards"": {
                ""xp"": 100
            }
        }");

        File.WriteAllText(Path.Combine(npcQuestPath, "quest_1.json"), @"{
            ""id"": ""quest_1"",
            ""repeatable"": false,
            ""objective"": {
                ""type"": ""talk_npc"",
                ""target"": ""npc_quest"",
                ""required_amount"": 3
            },
            ""rewards"": {
                ""xp"": 100
            }
        }");

        builder.UseContentRoot(realContentRoot);

        builder.ConfigureServices(services =>
        {
            // Replace the environments
            var envDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(IWebHostEnvironment));
            if (envDescriptor != null) services.Remove(envDescriptor);

            var hostEnvDescriptor = services.FirstOrDefault(d => d.ServiceType == typeof(IHostEnvironment));
            if (hostEnvDescriptor != null) services.Remove(hostEnvDescriptor);

            var testEnv = new TestWebHostEnvironment(_tempContentRoot, realContentRoot);
            services.AddSingleton<IWebHostEnvironment>(testEnv);
            services.AddSingleton<IHostEnvironment>(testEnv);

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

    private static void CopyDirectory(string sourceDir, string destinationDir)
    {
        Directory.CreateDirectory(destinationDir);
        foreach (var file in Directory.GetFiles(sourceDir))
        {
            File.Copy(file, Path.Combine(destinationDir, Path.GetFileName(file)), true);
        }
        foreach (var subDir in Directory.GetDirectories(sourceDir))
        {
            CopyDirectory(subDir, Path.Combine(destinationDir, Path.GetFileName(subDir)));
        }
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        if (disposing)
        {
            try
            {
                if (_tempContentRoot != null && Directory.Exists(_tempContentRoot))
                {
                    Directory.Delete(_tempContentRoot, true);
                }
            }
            catch
            {
                // Ignore cleanup errors
            }
        }
    }
}

public class TestWebHostEnvironment : IWebHostEnvironment
{
    public TestWebHostEnvironment(string contentRootPath, string realContentRoot)
    {
        ContentRootPath = contentRootPath;
        EnvironmentName = "Development";
        ApplicationName = "NMTales.Backend";
        WebRootPath = Path.Combine(realContentRoot, "wwwroot");
        ContentRootFileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(contentRootPath);
        
        if (Directory.Exists(WebRootPath))
        {
            WebRootFileProvider = new Microsoft.Extensions.FileProviders.PhysicalFileProvider(WebRootPath);
        }
        else
        {
            WebRootFileProvider = ContentRootFileProvider;
        }
    }

    public string ContentRootPath { get; set; }
    public string WebRootPath { get; set; }
    public Microsoft.Extensions.FileProviders.IFileProvider WebRootFileProvider { get; set; }
    public string ApplicationName { get; set; }
    public Microsoft.Extensions.FileProviders.IFileProvider ContentRootFileProvider { get; set; }
    public string EnvironmentName { get; set; }
}
