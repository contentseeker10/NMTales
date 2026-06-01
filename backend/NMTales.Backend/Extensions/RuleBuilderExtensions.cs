using FluentValidation;

namespace NMTales.Backend.Extensions;

public static class RuleBuilderExtensions
{
    public static void Password<T>(this IRuleBuilder<T, string> ruleBuilder, int minLength = 6)
    {
        ruleBuilder
            .MinimumLength(minLength).WithMessage($"Password must be at least {minLength} characters long.");
    }

    public static void Username<T>(this IRuleBuilder<T, string> ruleBuilder, int minLength = 3)
    {
        ruleBuilder
            .NotEmpty().WithMessage("Username is required.")
            .Length(minLength, 20).WithMessage($"Username must be between {minLength} and 20 characters.")
            .Matches("^[a-zA-Z0-9_]+$").WithMessage("Username can only contain letters, numbers, and underscores.");
    }
}