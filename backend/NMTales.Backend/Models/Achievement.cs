namespace NMTales.Backend.Models
{
    public class Achievement
    {
        public int Id { get; set; }
        public string Code { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public int XpReward { get; set; }
    }
}
