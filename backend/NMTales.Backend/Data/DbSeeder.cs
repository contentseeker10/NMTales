using NMTales.Backend.enums;
using NMTales.Backend.Models;

namespace NMTales.Backend.Data
{
    /// <summary>
    /// Populates the database with starter content on startup. Idempotent: it only
    /// seeds when no questions exist yet, so repeated boots are safe.
    /// </summary>
    public static class DbSeeder
    {
        public static void Seed(ApplicationDbContext context)
        {
            if (!context.Questions.Any(q => q.Topic == "Logarithms" || q.Topic == "Syntax"))
            {
                context.Questions.AddRange(TestSpecificMathQuestions());
                context.Questions.AddRange(TestSpecificUkrainianQuestions());
                context.SaveChanges();
            }

            if (!context.Questions.Any(q => q.Topic == "Math_1" || q.Topic == "Lang_1"))
            {
                context.Questions.AddRange(GameMathQuestions());
                context.Questions.AddRange(GameUkrainianQuestions());
                context.SaveChanges();
            }

            if (!context.Achievements.Any())
            {
                context.Achievements.AddRange(DefaultAchievements());
                context.SaveChanges();
            }
        }

        // --- Original questions for backend integration tests ---
        private static IEnumerable<Question> TestSpecificMathQuestions()
        {
            yield return Math("Logarithms", "Обчисліть: log₂(8)", "/images/math/log_eq1.png",
                ("2", false), ("3", true), ("4", false), ("8", false));

            yield return Math("Logarithms", "Обчисліть: log₃(81)", "/images/math/log_eq2.png",
                ("2", false), ("3", false), ("4", true), ("5", false));

            yield return Math("Logarithms", "Обчисліть: log₅(25)", "/images/math/log_eq3.png",
                ("1", false), ("2", true), ("3", false), ("5", false));

            yield return Math("Logarithms", "Обчисліть: log₁₀(1000)", "/images/math/log_eq4.png",
                ("2", false), ("3", true), ("4", false), ("10", false));

            yield return Math("Logarithms", "Обчисліть: log₂(1/4)", "/images/math/log_eq5.png",
                ("-2", true), ("2", false), ("-1", false), ("4", false));

            yield return Math("Logarithms", "Обчисліть: log₇(1)", "/images/math/log_eq6.png",
                ("0", true), ("1", false), ("7", false), ("-1", false));

            yield return Math("Logarithms", "Обчисліть: log₂(16)", "/images/math/log_eq7.png",
                ("2", false), ("4", true), ("8", false), ("16", false));

            yield return Math("Logarithms", "Обчисліть: ln(e³)", "/images/math/log_eq8.png",
                ("1", false), ("e", false), ("3", true), ("e³", false));
        }

        private static IEnumerable<Question> TestSpecificUkrainianQuestions()
        {
            yield return Scroll("Syntax", "У лісі росла [0] ялинка, а під нею сиділа [1] білка.",
                ("висока", 0), ("руда", 1), ("синій", null), ("швидко", null));

            yield return Scroll("Syntax", "На небі яскраво світило [0] сонце, і дув [1] вітер.",
                ("тепле", 0), ("легкий", 1), ("холодна", null), ("гучно", null));

            yield return Scroll("Syntax", "Біля [0] річки стояв [1] будинок.",
                ("широкої", 0), ("старий", 1), ("зелене", null), ("швидкий", null));
        }

        // --- Game-specific questions for progression ---
        private static IEnumerable<Question> GameMathQuestions()
        {
            // --- Math_1: Logarithms ---
            yield return Math("Math_1", "Обчисліть: log₂(8)", "/images/math/log_eq1.png",
                ("3", true), ("2", false), ("4", false), ("8", false));

            yield return Math("Math_1", "Обчисліть: log₃(81)", "/images/math/log_eq2.png",
                ("4", true), ("3", false), ("9", false), ("27", false));

            yield return Math("Math_1", "Обчисліть: log₅(1/25)", "/images/math/log_eq3.png",
                ("-2", true), ("2", false), ("-1", false), ("5", false));

            yield return Math("Math_1", "Знайдіть значення виразу: log₆(2) + log₆(18)", "/images/math/log_eq4.png",
                ("2", true), ("6", false), ("36", false), ("3", false));

            yield return Math("Math_1", "Обчисліть: log₇(√7)", "/images/math/log_eq5.png",
                ("0.5", true), ("1", false), ("7", false), ("2", false));

            // --- Math_2: Equations ---
            yield return Math("Math_2", "Розв'яжіть рівняння: x² - 5x + 6 = 0", "/images/math/eq1.png",
                ("x = 2; 3", true), ("x = -2; -3", false), ("x = 1; 6", false), ("x = -1; -6", false));

            yield return Math("Math_2", "Розв'яжіть рівняння: 2^x = 16", "/images/math/eq2.png",
                ("x = 4", true), ("x = 3", false), ("x = 8", false), ("x = 2", false));

            yield return Math("Math_2", "Розв'яжіть рівняння: log₃(x) = 2", "/images/math/eq3.png",
                ("x = 9", true), ("x = 6", false), ("x = 3", false), ("x = 2", false));

            yield return Math("Math_2", "Розв'яжіть рівняння: 3x - 12 = 0", "/images/math/eq4.png",
                ("x = 4", true), ("x = -4", false), ("x = 3", false), ("x = 12", false));

            // --- Math_3: Functions ---
            yield return Math("Math_3", "Знайдіть похідну функції: f(x) = x³", "/images/math/func1.png",
                ("f'(x) = 3x²", true), ("f'(x) = x²", false), ("f'(x) = 3x", false), ("f'(x) = 2x³", false));

            yield return Math("Math_3", "Знайдіть критичні точки функції: f(x) = x² - 4x", "/images/math/func2.png",
                ("x = 2", true), ("x = 4", false), ("x = 0", false), ("x = -2", false));

            yield return Math("Math_3", "Знайдіть похідну функції: f(x) = sin(x) + 2", "/images/math/func3.png",
                ("f'(x) = cos(x)", true), ("f'(x) = -cos(x)", false), ("f'(x) = cos(x) + 2", false), ("f'(x) = sin(x)", false));
        }

        private static Question Math(string topic, string text, string imagePath, params (string Text, bool IsCorrect)[] options)
        {
            return new Question
            {
                Subject = Subject.Math,
                Topic = topic,
                Text = text,
                ImagePath = imagePath,
                Answers = options
                    .Select(o => new Answer { Text = o.Text, IsCorrect = o.IsCorrect })
                    .ToList()
            };
        }

        private static IEnumerable<Question> GameUkrainianQuestions()
        {
            // --- Lang_1: Syntax (Exactly 12 drag and drop options) ---
            yield return Scroll("Lang_1", "На [0] галявині росли [1] квіти, а [2] бджоли [3] збирали солодкий [4] нектар у [5] вулики.",
                ("зеленій", 0), ("красиві", 1), ("працьовиті", 2), ("весело", 3), ("липовий", 4), ("старі", 5),
                ("червоний", null), ("швидко", null), ("співати", null), ("гучно", null), ("велике", null), ("холодий", null));

            yield return Scroll("Lang_1", "Учень [0] прочитав [1] книжку, яку йому [2] порадив [3] вчитель під час [4] цікавого [5] уроку.",
                ("уважно", 0), ("довгу", 1), ("вчора", 2), ("мудрий", 3), ("останнього", 4), ("історії", 5),
                ("бігти", null), ("швидкий", null), ("радісно", null), ("вікно", null), ("зелена", null), ("читати", null));

            // --- Lang_2: Orthography (Exactly 12 drag and drop options) ---
            yield return Scroll("Lang_2", "Промовте заклинання, щоб розвіяти темряву: «Нехай світло [0] осяє це похмуре [1]. Лише [2] воїн побачить [3] знак у [4] храмі, і сила [5] руни повернеться».",
                ("пречисте", 0), ("міжгір'я", 1), ("чесний", 2), ("тьмяний", 3), ("священному", 4), ("п'ятої", 5),
                ("причисте", null), ("міжгіря", null), ("честний", null), ("тмяний", null), ("священому", null), ("пятої", null));

            yield return Scroll("Lang_2", "Відновіть захисний напис на плиті: «Коли [0] промінь торкнеться землі, згасне [1] полум'я. [2] дух принесе [3] вість у [4] серце фортеці, руйнуючи [5] прокляття».",
                ("ранній", 0), ("тьмяне", 1), ("премудрий", 2), ("радісну", 3), ("кам'яне", 4), ("дев'яте", 5),
                ("раній", null), ("тмяне", null), ("примудрий", null), ("радістну", null), ("камяне", null), ("девяте", null));

            // --- Lang_3: Phonetics (Exactly 12 drag and drop options) ---
            yield return Scroll("Lang_3", "Класифікуйте звуки: голосні — [0], [1]; приголосні дзвінкі — [2], [3]; приголосні глухі — [4], [5].",
                ("[а]", 0), ("[о]", 1), ("[дз]", 2), ("[ж]", 3), ("[п]", 4), ("[т]", 5),
                ("[й]", null), ("[в]", null), ("[м]", null), ("[н]", null), ("[л]", null), ("[р]", null));

            yield return Scroll("Lang_3", "Знайдіть м'які приголосні: [0], [1], [2], та тверді приголосні: [3], [4], [5].",
                ("[д']", 0), ("[т']", 1), ("[л']", 2), ("[б]", 3), ("[к]", 4), ("[п]", 5),
                ("[ж]", null), ("[ч]", null), ("[ш]", null), ("[р]", null), ("[ц]", null), ("[ф]", null));
        }

        private static Question Scroll(string topic, string text, params (string Text, int? Slot)[] options)
        {
            return new Question
            {
                Subject = Subject.Ukrainian,
                Topic = topic,
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
                Title = "Polymath",
                Description = "Talk to all three assistant NPCs",
                XpReward = 150
            };

            yield return new Achievement
            {
                Code = "complete_all_quests",
                Title = "NMTales Hero",
                Description = "Complete all quests in the game",
                XpReward = 300
            };

            yield return new Achievement
            {
                Code = "kill_100_vampires",
                Title = "Vampire Slayer",
                Description = "Defeat 100 vampires",
                XpReward = 250
            };

            yield return new Achievement
            {
                Code = "unlock_all_spawns",
                Title = "Explorer",
                Description = "Discover all vampire spawn points",
                XpReward = 200
            };

            yield return new Achievement
            {
                Code = "flawless_run",
                Title = "Immortal Scientist",
                Description = "Complete the game without failing any tests or dying",
                XpReward = 500
            };
        }
    }
}
