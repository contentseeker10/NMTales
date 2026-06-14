using System.Collections.Generic;
using System.Text.Json;

namespace NMTales.Backend.Models
{
    public class PlayerStats
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public User? User { get; set; }
        public int VampireKills { get; set; }
        public int CompletedQuestsCount { get; set; }
        public int DeathsCount { get; set; }
        public int FailedTestsCount { get; set; }
        public string UnlockedSpawnPoints { get; set; } = "[]";
        public string TalkedAssistants { get; set; } = "[]";
        public bool HasFailedTest { get; set; }
        public bool HasDied { get; set; }

        public List<string> GetUnlockedSpawnPoints()
        {
            if (string.IsNullOrEmpty(UnlockedSpawnPoints))
                return new List<string>();
            try
            {
                return JsonSerializer.Deserialize<List<string>>(UnlockedSpawnPoints) ?? new List<string>();
            }
            catch
            {
                return new List<string>();
            }
        }

        public void SetUnlockedSpawnPoints(List<string> points)
        {
            UnlockedSpawnPoints = JsonSerializer.Serialize(points);
        }

        public List<string> GetTalkedAssistants()
        {
            if (string.IsNullOrEmpty(TalkedAssistants))
                return new List<string>();
            try
            {
                return JsonSerializer.Deserialize<List<string>>(TalkedAssistants) ?? new List<string>();
            }
            catch
            {
                return new List<string>();
            }
        }

        public void SetTalkedAssistants(List<string> assistants)
        {
            TalkedAssistants = JsonSerializer.Serialize(assistants);
        }
    }
}
