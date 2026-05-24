using NMTale.enums;

namespace NMTales.Models
{
    public class Location
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public int RequiredLevel { get; set; }

        public Subject Subject { get; set; }
    }
}