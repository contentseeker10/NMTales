using Microsoft.AspNetCore.Mvc;
using NMTale.Services;

namespace NMTale.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class QuestionController : ControllerBase
    {
        private readonly QuestionService _questionService;

        public QuestionController(QuestionService questionService)
        {
            _questionService = questionService;
        }

        [HttpGet]
        public async Task<IActionResult> GetQuestions()
        {
            var questions =
                await _questionService.GetQuestions();

            return Ok(questions);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetQuestion(int id)
        {
            var question =
                await _questionService.GetQuestionById(id);

            if (question == null)
            {
                return NotFound();
            }

            return Ok(question);
        }

        [HttpPost("check")]
        public async Task<IActionResult> CheckAnswer(
            int questionId,
            int answerId)
        {
            var isCorrect =
                await _questionService.CheckAnswer(
                    questionId,
                    answerId);

            return Ok(new
            {
                correct = isCorrect
            });
        }
    }
}