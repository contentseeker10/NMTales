using NMTale.enums;
using NMTales.Models;

namespace NMTale.Models
{
    public class NPC
    {
        public int Id { get; set; }

        public string Name { get; set; } = string.Empty;

        public Subject Subject { get; set; }

        public string Description { get; set; } = string.Empty;

        public string PersonalityPrompt { get; set; } = string.Empty;

        public int LocationId { get; set; }

        public Location? Location { get; set; }
    }
}