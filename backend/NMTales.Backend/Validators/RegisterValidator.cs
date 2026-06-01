using FluentValidation;
using Microsoft.EntityFrameworkCore;
using NMTales.Backend.Data;
using NMTales.Backend.DTO;
using NMTales.Backend.Extensions;

namespace NMTales.Backend.Validators;

public class RegisterValidator : AbstractValidator<RegisterDto>
{
    private readonly ApplicationDbContext _context;

    public RegisterValidator(ApplicationDbContext context)
    {
        _context = context;

        RuleFor(x => x.Username)
            .MustAsync(IsUniqueUsername).WithMessage("Username already exists")
            .Username();
        RuleFor(x => x.Password).Password();
    }

    private async Task<bool> IsUniqueUsername(string username, CancellationToken cancellationToken)
    {
        if (string.IsNullOrEmpty(username)) return true; 
        
        bool exists = await _context.Users.AnyAsync(x => x.Username == username, cancellationToken);
        return !exists;
    }
}