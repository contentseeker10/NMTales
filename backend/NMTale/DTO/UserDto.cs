using NMTale.Models;

namespace NMTale.DTO
{
    public class UserDto
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public int XP { get; set; }
        public int Level { get; set; }

        public static UserDto FromModel(User user)
        {
            return new UserDto
            {
                Id = user.Id,
                Username = user.Username,
                XP = user.XP,
                Level = user.Level
            };
        }
    }
}
