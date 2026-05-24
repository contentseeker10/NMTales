namespace NMTales.Models
{
    public class UserProgress
    {
        public int Id { get; set; }

        public int UserId { get; set; }

        public int LocationId { get; set; }

        public int TotalExp { get; set; }

        public int NeededExp { get; set; }

        public double Progress =>
            NeededExp == 0
                ? 0
                : (double)TotalExp / NeededExp;
    }
}