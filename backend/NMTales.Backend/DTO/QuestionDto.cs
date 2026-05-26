namespace NMTales.Backend.DTO
{
    public class QuestionDto
    {
        public int Id { get; set; }
        public string Subject { get; set; } = string.Empty;
        public string Text { get; set; } = string.Empty;
        public string? Image { get; set; }
        public List<string> Answers { get; set; } = new();
    }
}
