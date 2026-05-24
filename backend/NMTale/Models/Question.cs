using NMTale.enums;
using NMTale.DTO;

namespace NMTale.Models
{
    public class Question
    {
        public int Id { get; set; }
        public Subject Subject { get; set; }

        public string Text { get; set; } = string.Empty;
        public string? Image { get; set; }
        public List<AnswerDto> Answers { get; set; } = new();
    }

}
