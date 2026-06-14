using NMTales.Backend.enums;
using NMTales.Backend.Models;

namespace NMTales.Backend.Data
{
    /// <summary>
    /// Populates the in-memory database with starter content on startup. Idempotent: it only
    /// seeds when no questions exist yet, so repeated boots (and per-test factories) are safe.
    /// </summary>
    public static class DbSeeder
    {
        public static void Seed(ApplicationDbContext context)
        {
            if (!context.Questions.Any())
            {
                context.Questions.AddRange(MathQuestions());
                context.Questions.AddRange(UkrainianQuestions());
                context.SaveChanges();
            }

            if (!context.Achievements.Any())
            {
                context.Achievements.AddRange(DefaultAchievements());
                context.SaveChanges();
            }
        }

        // --- Math altar: topic "Logarithms" -------------------------------------------------
        // Enough unique questions to exercise random, no-repeat selection of 3 at a time.
        private static IEnumerable<Question> MathQuestions()
        {
            yield return Math("Обчисліть: log₂(8)", "/images/math/log_eq1.png",
                ("2", false), ("3", true), ("4", false), ("8", false));

            yield return Math("Обчисліть: log₃(81)", "/images/math/log_eq2.png",
                ("2", false), ("3", false), ("4", true), ("5", false));

            yield return Math("Обчисліть: log₅(25)", "/images/math/log_eq3.png",
                ("1", false), ("2", true), ("3", false), ("5", false));

            yield return Math("Обчисліть: log₁₀(1000)", "/images/math/log_eq4.png",
                ("2", false), ("3", true), ("4", false), ("10", false));

            yield return Math("Обчисліть: log₂(1/4)", "/images/math/log_eq5.png",
                ("-2", true), ("2", false), ("-1", false), ("4", false));

            yield return Math("Обчисліть: log₇(1)", "/images/math/log_eq6.png",
                ("0", true), ("1", false), ("7", false), ("-1", false));

            yield return Math("Обчисліть: log₂(16)", "/images/math/log_eq7.png",
                ("2", false), ("4", true), ("8", false), ("16", false));

            yield return Math("Обчисліть: ln(e³)", "/images/math/log_eq8.png",
                ("1", false), ("e", false), ("3", true), ("e³", false));
        }

        private static Question Math(string text, string imagePath, params (string Text, bool IsCorrect)[] options)
        {
            return new Question
            {
                Subject = Subject.Math,
                Topic = "Logarithms",
                Text = text,
                ImagePath = imagePath,
                Answers = options
                    .Select(o => new Answer { Text = o.Text, IsCorrect = o.IsCorrect })
                    .ToList()
            };
        }

        // --- Ukrainian scroll: topic "Syntax" -----------------------------------------------
        // Each scroll has two real slots plus distractors (CorrectSlotIndex == null).
        private static IEnumerable<Question> UkrainianQuestions()
        {
            yield return Scroll("У лісі росла [0] ялинка, а під нею сиділа [1] білка.",
                ("висока", 0), ("руда", 1), ("синій", null), ("швидко", null));

            yield return Scroll("На небі яскраво світило [0] сонце, і дув [1] вітер.",
                ("тепле", 0), ("легкий", 1), ("холодна", null), ("гучно", null));

            yield return Scroll("Біля [0] річки стояв [1] будинок.",
                ("широкої", 0), ("старий", 1), ("зелене", null), ("швидкий", null));
        }

        private static Question Scroll(string text, params (string Text, int? Slot)[] options)
        {
            return new Question
            {
                Subject = Subject.Ukrainian,
                Topic = "Syntax",
                Text = text,
                ImagePath = null,
                Answers = options
                    .Select(o => new Answer { Text = o.Text, CorrectSlotIndex = o.Slot })
                    .ToList()
            };
        }

        private static IEnumerable<Achievement> DefaultAchievements()
        {
            yield return new Achievement
            {
                Code = "talk_all_assistants",
                Title = "Ерудит",
                Description = "Поговорити з усіма трьома асистентами (Математика, Мова, Історія)",
                XpReward = 150
            };

            yield return new Achievement
            {
                Code = "complete_all_quests",
                Title = "Герой NMTales",
                Description = "Виконати всі квести в грі",
                XpReward = 300
            };

            yield return new Achievement
            {
                Code = "kill_100_vampires",
                Title = "Винищувач вампірів",
                Description = "Перемогти 100 вампірів",
                XpReward = 250
            };

            yield return new Achievement
            {
                Code = "unlock_all_spawns",
                Title = "Дослідник",
                Description = "Відкрити всі точки спавну вампірів",
                XpReward = 200
            };

            yield return new Achievement
            {
                Code = "flawless_run",
                Title = "Безсмертний вчений",
                Description = "Пройти гру без помилок у тестах та смертей",
                XpReward = 500
            };
        }
    }
}
