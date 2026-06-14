using NMTales.Backend.Repositories.Location;

namespace NMTales.Backend.Services.Location;

public class LocationService : ILocationService
{
    private readonly ILocationRepository _locationRepository;
    public LocationService(ILocationRepository locationRepository)
    {
        this._locationRepository = locationRepository;
    }
    
    public async Task<Models.Location?> GetLocationByNameAsync(string locationName)
    {
        return await _locationRepository.GetLocationByNameAsync(locationName);
    }
}