using FluentValidation;
using NMTales.Backend.DTO;

namespace NMTales.Backend.Validators;

public class UpdatePlayerLocationValidator : AbstractValidator<UpdatePlayerLocationDto>
{
    public UpdatePlayerLocationValidator()
    {
        RuleFor(x => x.CurrentLocation)
            .NotEmpty().WithMessage("Current location must not be empty.");
    }
}
