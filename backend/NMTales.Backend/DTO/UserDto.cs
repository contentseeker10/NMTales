using NMTales.Backend.Models;

namespace NMTales.Backend.DTO
{
    public class UserDto
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public int XP { get; set; }
        public int Level { get; set; }
        public string CurrentLocation { get; set; } = string.Empty;
        public double CurrentPositionX { get; set; }
        public double CurrentPositionY { get; set; }

        public static UserDto FromModel(User user)
        {
            return new UserDto
            {
                Id = user.Id,
                Username = user.Username,
                XP = user.XP,
                Level = user.Level,
                CurrentLocation = user.CurrentLocation,
                CurrentPositionX = user.CurrentPositionX,
                CurrentPositionY = user.CurrentPositionY
            };
        }
    }
}
