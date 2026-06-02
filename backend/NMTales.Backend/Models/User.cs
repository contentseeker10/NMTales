namespace NMTales.Backend.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public int XP { get; set; }
        public int Level { get; set; } = 1;
        public string CurrentLocation { get; set; } = "test";
        public double CurrentPositionX { get; set; } = 0.0;
        public double CurrentPositionY { get; set; } = 0.0;
    }
}
