namespace NMTales.Backend.Repositories.Location;

public interface ILocationRepository : IRepository<Models.Location>
{
    Task<Models.Location?> GetLocationByNameAsync(string locationName);
}