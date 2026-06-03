namespace NMTales.Backend.DTO
{
    public class StartTestRequestDto
    {
        // Sent as a string, e.g. "Math" or "Ukrainian"; parsed to the Subject enum server-side.
        public string Subject { get; set; } = string.Empty;

        public string Topic { get; set; } = string.Empty;
    }
}
