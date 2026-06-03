using NMTales.Backend.Models;

namespace NMTales.Backend.DTO
{
    /// <summary>
    /// A question as the client is allowed to see it: no IsCorrect / CorrectSlotIndex flags,
    /// so the answer cannot be derived from the payload.
    /// </summary>
    public class TestQuestionDto
    {
        public int Id { get; set; }
        public string Text { get; set; } = string.Empty;
        public string? ImagePath { get; set; }
        public List<AnswerDto> Answers { get; set; } = new();

        public static TestQuestionDto FromModel(Question question)
        {
            return new TestQuestionDto
            {
                Id = question.Id,
                Text = question.Text,
                ImagePath = question.ImagePath,
                Answers = question.Answers
                    .Select(answer => new AnswerDto { Id = answer.Id, Text = answer.Text })
                    .ToList()
            };
        }
    }
}
