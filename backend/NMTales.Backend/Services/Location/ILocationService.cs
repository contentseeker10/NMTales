namespace NMTales.Backend.Services.Location;

public interface ILocationService
{
    Task<Models.Location?> GetLocationByNameAsync(string locationName);
}