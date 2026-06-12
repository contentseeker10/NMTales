using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;

namespace NMTales.Backend.Repositories.Location;

public class LocationRepository : Repository<Models.Location>, ILocationRepository
{
    public LocationRepository(ApplicationDbContext context) : base(context)
    {
    }

    public async Task<Models.Location?> GetLocationByNameAsync(string locationName)
    {
        return await _dbSet.FirstOrDefaultAsync(l => l.Name == locationName);
    }
}