using NMTales.Backend.enums;

namespace NMTales.Backend.Models
{
    public class Achievement
    {
        public int Id { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public Reward Reward { get; set; }
    }
}
