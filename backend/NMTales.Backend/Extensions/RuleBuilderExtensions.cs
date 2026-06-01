using FluentValidation;

namespace NMTales.Backend.Extensions;

public static class RuleBuilderExtensions
{
    public static void Password<T>(this IRuleBuilder<T, string> ruleBuilder, int minLength = 8)
    {
        ruleBuilder
            .MinimumLength(minLength).WithMessage($"Password must be at least {minLength} characters long.")
            .Matches("[A-Z]").WithMessage("Password must contain at least one uppercase letter.")
            .Matches("[a-z]").WithMessage("Password must contain at least one lowercase letter.")
            .Matches("[0-9]").WithMessage("Password must contain at least one number.")
            .Matches("[^a-zA-Z0-9]").WithMessage("Password must contain at least one special symbol.");
    }

    public static void Username<T>(this IRuleBuilder<T, string> ruleBuilder, int minLength = 3)
    {
        ruleBuilder
            .NotEmpty().WithMessage("Username is required.")
            .Length(minLength, 20).WithMessage($"Username must be between {minLength} and 20 characters.")
            .Matches("^[a-zA-Z0-9_]+$").WithMessage("Username can only contain letters, numbers, and underscores.");
    }
}