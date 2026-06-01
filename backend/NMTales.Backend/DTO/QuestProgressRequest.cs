namespace NMTales.Backend.DTO
{
    public class QuestProgressRequest
    {
        public string EventType { get; set; } = string.Empty; // e.g., "talk_npc", "enter_location"
        public string Target { get; set; } = string.Empty;    // e.g., "npc_test"
    }
}
