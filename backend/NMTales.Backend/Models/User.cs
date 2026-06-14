namespace NMTales.Backend.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public int XP { get; set; }
        public int Level { get; set; } = 1;
        public string CurrentLocation { get; set; } = "main";
        public double CurrentPositionX { get; set; } = 0.0;
        public double CurrentPositionY { get; set; } = 0.0;
        public int CurrentHp { get; set; } = 80;
        public int MaxHp { get; set; } = 80;
        public bool IsDead { get; set; } = false;
        public DateTime? LastAttackTimeUtc { get; set; }

        /// <summary>
        /// Award XP and apply any resulting level-ups. The XP required for the next level is
        /// (Level + 1) * 100. Single source of truth for the leveling curve so every reward
        /// path (quests, tests) stays in sync.
        /// </summary>
        public void AddXp(int amount)
        {
            XP += amount;

            var neededXp = (Level + 1) * 100;
            while (XP >= neededXp)
            {
                XP -= neededXp;
                Level += 1;
                neededXp = (Level + 1) * 100;
            }
        }
    }
}
