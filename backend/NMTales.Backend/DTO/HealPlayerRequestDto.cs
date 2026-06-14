namespace NMTales.Backend.DTO
{
    public class HealPlayerRequestDto
    {
        public string PlantId { get; set; } = string.Empty;
        public double PositionX { get; set; }
        public double PositionY { get; set; }
    }
}
