using NMTales.Backend.Models;

namespace NMTales.Backend.Models
{
    public class Answer
    {
        public int Id { get; set; }

        public int QuestionId { get; set; }

        public Question? Question { get; set; }

        public string Text { get; set; } = string.Empty;

        public bool IsCorrect { get; set; }
    }
}
