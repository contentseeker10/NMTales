namespace NMTales.Backend.Models
{
    public class Answer
    {
        public int Id { get; set; }

        public int QuestionId { get; set; }

        public Question? Question { get; set; }

        // Answer text, or the draggable element for a Drag & Drop scroll.
        public string Text { get; set; } = string.Empty;

        // Math: marks the single correct option for a multiple-choice question.
        public bool IsCorrect { get; set; }

        // Ukrainian (Drag & Drop): the placeholder slot [x] in the question text this
        // element belongs in. null means it is a distractor (a deliberately wrong option).
        public int? CorrectSlotIndex { get; set; }
    }
}
