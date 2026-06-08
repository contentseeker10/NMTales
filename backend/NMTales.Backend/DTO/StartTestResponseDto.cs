namespace NMTales.Backend.DTO
{
    public class StartTestResponseDto
    {
        public int SessionId { get; set; }
        public string Subject { get; set; } = string.Empty;
        public string Topic { get; set; } = string.Empty;
        public int CurrentQuestionIndex { get; set; }
        public int TotalQuestions { get; set; }
        public TestQuestionDto Question { get; set; } = new();
    }
}
