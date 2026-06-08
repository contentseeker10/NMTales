using FluentValidation;
using NMTales.Backend.DTO;

namespace NMTales.Backend.Validators;

public class UpdateNotebookPageValidator : AbstractValidator<UpdateNotebookPageDto>
{
    public UpdateNotebookPageValidator()
    {
        RuleFor(x => x.Title)
            .NotEmpty().WithMessage("Title must not be empty.")
            .MaximumLength(20).WithMessage("Title must be at most 20 characters.");

        RuleFor(x => x.Content)
            .MaximumLength(10000).WithMessage("Content must be at most 10000 characters.");
    }
}