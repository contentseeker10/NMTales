using System;

namespace NMTales.Backend.Models
{
    public class UserAchievement
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User? User { get; set; }
        public int AchievementId { get; set; }
        public Achievement? Achievement { get; set; }
        public DateTime UnlockedAtUtc { get; set; }
    }
}
