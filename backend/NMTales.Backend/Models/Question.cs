using NMTales.Backend.enums;

namespace NMTales.Backend.Models
{
    public class Question
    {
        public int Id { get; set; }
        public Subject Subject { get; set; }

        // Topic groups questions inside a subject, e.g. "Logarithms", "Fractions", "Syntax".
        public string Topic { get; set; } = string.Empty;

        // Question text. May contain Drag & Drop placeholders such as "У лісі росла [0] ялинка...".
        public string Text { get; set; } = string.Empty;

        // Path to an illustration in wwwroot (e.g. a rendered LaTeX formula), or null.
        public string? ImagePath { get; set; }

        public List<Answer> Answers { get; set; } = new();
    }
}
