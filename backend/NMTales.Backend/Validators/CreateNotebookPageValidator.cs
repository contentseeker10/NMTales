using FluentValidation;
using NMTales.Backend.DTO;

namespace NMTales.Backend.Validators;

public class CreateNotebookPageValidator : AbstractValidator<CreateNotebookPageDto>
{
    public CreateNotebookPageValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Title must not be empty.")
            .MaximumLength(20).WithMessage("Title must be at most 20 characters.");
    }
}