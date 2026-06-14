using NMTales.Backend.enums;

namespace NMTales.Backend.Services;

/// <summary>
/// Subject parsing + the Ukrainian system prompt that turns Gemini into a school tutor for
/// each subject. Keeping the personas server-side means the client can't tamper with the
/// tutor's behaviour (e.g. to coax out test answers).
/// </summary>
public static class AssistantPersona
{
    /// <summary>
    /// Resolves the subject string the client sends. Accepts the test-system enum names plus
    /// the client's "Language" alias for <see cref="Subject.Ukrainian"/> (the NPC export enum
    /// uses Math/Language/History).
    /// </summary>
    public static bool TryParseSubject(string? raw, out Subject subject)
    {
        subject = default;
        if (string.IsNullOrWhiteSpace(raw))
        {
            return false;
        }

        switch (raw.Trim().ToLowerInvariant())
        {
            case "math":
                subject = Subject.Math;
                return true;
            case "language":
            case "ukrainian":
                subject = Subject.Ukrainian;
                return true;
            case "history":
                subject = Subject.History;
                return true;
            default:
                return false;
        }
    }

    public static string SystemInstruction(Subject subject)
    {
        var (subjectGen, focus) = subject switch
        {
            Subject.Math => (
                "математики",
                "Розв'язуй задачі покроково: спершу назви потрібне правило чи формулу, потім покажи приклад, і лише тоді — саме розв'язання."),
            Subject.Ukrainian => (
                "української мови та літератури",
                "Пояснюй правила орфографії, граматики й пунктуації, допомагай розбирати слова та речення і наводь приклади."),
            Subject.History => (
                "історії",
                "Розповідай про історичні події цікаво й доступно, пояснюй причини та наслідки, згадуй важливі дати й постаті."),
            _ => (
                "шкільних предметів",
                "Допомагай учневі розібратися в матеріалі простими словами."),
        };

        return $"""
            Ти — доброзичливий і терплячий вчитель {subjectGen} у навчальній грі NMTales для українських школярів.

            Як ти спілкуєшся:
            - Тільки українською мовою, тепло й підбадьорливо, звертайся на «ти».
            - Коротко, як у живому чаті: зазвичай 2–5 речень. Пояснюй простими словами та наводь приклади.
            - {focus}
            - Твоя мета — щоб учень ЗРОЗУМІВ матеріал. Підказуй спосіб і наводь на думку, а не диктуй готові відповіді для контрольних чи тестів.
            - Якщо питання не стосується предмета ({subjectGen}) — м'яко поверни розмову до теми уроку.
            - Якщо учень помилився — лагідно виправ і похвали за старання.
            - Пиши звичайним текстом без Markdown і символів форматування (* _ # `).
            """;
    }
}
