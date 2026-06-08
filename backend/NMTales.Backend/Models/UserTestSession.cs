using NMTales.Backend.enums;

namespace NMTales.Backend.Models
{
    /// <summary>
    /// Server-authoritative state for one in-progress test run. Holds the chosen questions
    /// and the player's live progress so answers can be validated entirely on the server
    /// (the client never learns which option is correct).
    /// </summary>
    public class UserTestSession
    {
        public int Id { get; set; }

        public int UserId { get; set; }
        public User? User { get; set; }

        public Subject Subject { get; set; }
        public string Topic { get; set; } = string.Empty;

        // IDs of the questions chosen for this session, in order.
        // Math altar -> 3 unique random questions; Ukrainian scroll -> 1 question.
        public List<int> QuestionIds { get; set; } = new();

        // Index of the current question within QuestionIds (0 .. Count-1).
        public int CurrentQuestionIndex { get; set; }

        // Attempts left on the current question (default 2 for math).
        public int RemainingAttempts { get; set; }

        public bool IsCompleted { get; set; }
        public bool IsFailed { get; set; }
    }
}
