using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using Xunit;

namespace NMTales.Backend.Tests;

public class NotebookControllerTests
{
    private static async Task<HttpClient> CreateAuthenticatedClientAsync(QuestApiFactory factory, string username)
    {
        var client = factory.CreateClient();
        var response = await client.PostAsJsonAsync("/api/auth/register",
            new { username, password = "Secret123!" });
        response.EnsureSuccessStatusCode();

        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var token = doc.RootElement.GetProperty("token").GetString();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }

    [Fact]
    public async Task GetAllWithoutTokenReturnsUnauthorized()
    {
        using var factory = new QuestApiFactory();
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/notebook");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task GetAllWithNoPagesReturnsEmptyList()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user1");

        var response = await client.GetAsync("/api/notebook");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var pages = await response.Content.ReadFromJsonAsync<List<NotebookPageDto>>();
        Assert.NotNull(pages);
        Assert.Empty(pages);
    }

    [Fact]
    public async Task CreateWithValidTitleReturnsPageWithDefaultContent()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user2");

        var response = await client.PostAsJsonAsync("/api/notebook", new { title = "Нова сторінка" });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var page = await response.Content.ReadFromJsonAsync<NotebookPageDto>();
        Assert.NotNull(page);
        Assert.True(page.Id > 0);
        Assert.Equal("Нова сторінка", page.Title);
        Assert.Equal("Тут будуть потужні записи...", page.Content);
    }

    [Fact]
    public async Task CreateEleventhPageReturnsBadRequestWithLimitMessage()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user3");

        for (var i = 1; i <= 10; i++)
        {
            var response = await client.PostAsJsonAsync("/api/notebook", new { title = $"Page {i}" });
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        }

        var limitResponse = await client.PostAsJsonAsync("/api/notebook", new { title = "Page 11" });

        Assert.Equal(HttpStatusCode.BadRequest, limitResponse.StatusCode);
        Assert.Equal("Досягнуто ліміту сторінок блокнота (макс. 10)",
            await limitResponse.Content.ReadAsStringAsync());
    }

    [Fact]
    public async Task CreateWithEmptyTitleReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user4");

        var response = await client.PostAsJsonAsync("/api/notebook", new { title = "" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task CreateWithTitleOver20CharsReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user5");

        var response = await client.PostAsJsonAsync("/api/notebook",
            new { title = "This title is way too long" });

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task UpdateOwnPageReturnsNoContentAndPersistsChanges()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user6");

        var createResponse = await client.PostAsJsonAsync("/api/notebook", new { title = "Original" });
        var created = await createResponse.Content.ReadFromJsonAsync<NotebookPageDto>();
        Assert.NotNull(created);

        var updateResponse = await client.PutAsJsonAsync($"/api/notebook/{created.Id}", new
        {
            title = "Updated",
            content = "Note content here"
        });

        Assert.Equal(HttpStatusCode.NoContent, updateResponse.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        var page = db.NotebookPages.Single(p => p.Id == created.Id);
        Assert.Equal("Updated", page.Title);
        Assert.Equal("Note content here", page.Content);
    }

    [Fact]
    public async Task UpdateAnotherUsersPageReturnsNotFound()
    {
        using var factory = new QuestApiFactory();
        var client1 = await CreateAuthenticatedClientAsync(factory, "notebook_owner");
        var client2 = await CreateAuthenticatedClientAsync(factory, "notebook_intruder");

        var createResponse = await client1.PostAsJsonAsync("/api/notebook", new { title = "Private" });
        var created = await createResponse.Content.ReadFromJsonAsync<NotebookPageDto>();
        Assert.NotNull(created);

        var updateResponse = await client2.PutAsJsonAsync($"/api/notebook/{created.Id}", new
        {
            title = "Hacked",
            content = "Should not work"
        });

        Assert.Equal(HttpStatusCode.NotFound, updateResponse.StatusCode);
    }

    [Fact]
    public async Task UpdateWithContentOver10000CharsReturnsBadRequest()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user7");

        var createResponse = await client.PostAsJsonAsync("/api/notebook", new { title = "Page" });
        var created = await createResponse.Content.ReadFromJsonAsync<NotebookPageDto>();
        Assert.NotNull(created);

        var updateResponse = await client.PutAsJsonAsync($"/api/notebook/{created.Id}", new
        {
            title = "Page",
            content = new string('x', 10001)
        });

        Assert.Equal(HttpStatusCode.BadRequest, updateResponse.StatusCode);
    }

    [Fact]
    public async Task DeleteOwnPageReturnsNoContent()
    {
        using var factory = new QuestApiFactory();
        var client = await CreateAuthenticatedClientAsync(factory, "notebook_user8");

        var createResponse = await client.PostAsJsonAsync("/api/notebook", new { title = "To delete" });
        var created = await createResponse.Content.ReadFromJsonAsync<NotebookPageDto>();
        Assert.NotNull(created);

        var deleteResponse = await client.DeleteAsync($"/api/notebook/{created.Id}");

        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        Assert.False(db.NotebookPages.Any(p => p.Id == created.Id));
    }

    [Fact]
    public async Task DeleteAnotherUsersPageReturnsNotFound()
    {
        using var factory = new QuestApiFactory();
        var client1 = await CreateAuthenticatedClientAsync(factory, "notebook_owner2");
        var client2 = await CreateAuthenticatedClientAsync(factory, "notebook_intruder2");

        var createResponse = await client1.PostAsJsonAsync("/api/notebook", new { title = "Keep me" });
        var created = await createResponse.Content.ReadFromJsonAsync<NotebookPageDto>();
        Assert.NotNull(created);

        var deleteResponse = await client2.DeleteAsync($"/api/notebook/{created.Id}");

        Assert.Equal(HttpStatusCode.NotFound, deleteResponse.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
        Assert.True(db.NotebookPages.Any(p => p.Id == created.Id));
    }
}
