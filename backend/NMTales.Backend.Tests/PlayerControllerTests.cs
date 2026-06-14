using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using Xunit;

namespace NMTales.Backend.Tests;

public class PlayerControllerTests
{
    private static async Task<HttpClient> CreateAuthenticatedClientAsync(QuestApiFactory factory, string username)
    {
        var client = factory.CreateClient();
    
        // Create a guaranteed unique username under 20 characters
        // Example output: "u_a1b2c3d4e5f6" (14 characters total)
        var uniqueUsername = $"u_{Guid.NewGuid().ToString("N").Substring(0, 12)}";
    
        var response = await client.PostAsJsonAsync("/api/auth/register",
            new { username = uniqueUsername, password = "Secret123!" });
    
        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            throw new Exception($"SERVER CRASHED: {errorContent}");
        }

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var token = doc.RootElement.GetProperty("token").GetString();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    [Fact]
    public async Task UpdateLocation_WithoutToken_ReturnsUnauthorized()
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/player/location", new
        {
            currentLocation = "math",
            currentPositionX = 12.34,
            currentPositionY = 56.78
        });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task UpdateLocation_WithValidData_UpdatesUserLocationAndCoordinates()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "player1");

        var response = await client.PostAsJsonAsync("/api/player/location", new
        {
            currentLocation = "math",
            currentPositionX = 12.34,
            currentPositionY = 56.78
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var updatedUser = await response.Content.ReadFromJsonAsync<UserDto>();
        Assert.NotNull(updatedUser);
        Assert.Equal("math", updatedUser.CurrentLocation);
        Assert.Equal(12.34, updatedUser.CurrentPositionX);
        Assert.Equal(56.78, updatedUser.CurrentPositionY);

        // Double check in db
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var user = db.Users.Single(u => u.Id == updatedUser.Id);
        Assert.Equal("math", user.CurrentLocation);
        Assert.Equal(12.34, user.CurrentPositionX);
        Assert.Equal(56.78, user.CurrentPositionY);
    }

    [Fact]
    public async Task UpdateLocation_WithInvalidData_ReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "player2");

        var response = await client.PostAsJsonAsync("/api/player/location", new
        {
            currentLocation = "", // Invalid: Empty
            currentPositionX = 12.34,
            currentPositionY = 56.78
        });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetLocation_WithoutToken_ReturnsUnauthorized()
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/player/location");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetLocation_ReturnsCurrentUserLocationAndCoordinates()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "player3");

        // First check defaults
        var getResponse = await client.GetAsync("/api/player/location");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);

        using var doc = JsonDocument.Parse(await getResponse.Content.ReadAsStringAsync());
        Assert.Equal("main", doc.RootElement.GetProperty("currentLocation").GetString());
        Assert.Equal(0.0, doc.RootElement.GetProperty("currentPositionX").GetDouble());
        Assert.Equal(0.0, doc.RootElement.GetProperty("currentPositionY").GetDouble());

        // Update it
        var updateResponse = await client.PostAsJsonAsync("/api/player/location", new
        {
            currentLocation = "swamp",
            currentPositionX = -100.5,
            currentPositionY = 250.75
        });
        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);

        // Fetch again and verify updated values
        var getResponse2 = await client.GetAsync("/api/player/location");
        Assert.Equal(HttpStatusCode.OK, getResponse2.StatusCode);

        using var doc2 = JsonDocument.Parse(await getResponse2.Content.ReadAsStringAsync());
        Assert.Equal("swamp", doc2.RootElement.GetProperty("currentLocation").GetString());
        Assert.Equal(-100.5, doc2.RootElement.GetProperty("currentPositionX").GetDouble());
        Assert.Equal(250.75, doc2.RootElement.GetProperty("currentPositionY").GetDouble());
    }
}
