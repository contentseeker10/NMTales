namespace NMTales.Backend.DTO
{
    public class UpdatePlayerLocationDto
    {
        public string CurrentLocation { get; set; } = string.Empty;
        public double CurrentPositionX { get; set; }
        public double CurrentPositionY { get; set; }
    }
}
