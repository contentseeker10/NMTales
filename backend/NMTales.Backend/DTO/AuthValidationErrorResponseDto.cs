using FluentValidation.Results;

namespace NMTales.Backend.DTO;

public class AuthValidationErrorResponseDto
{
    public string Message { get; set; } = "One or more validation errors occurred.";
    public Dictionary<string, string[]> Errors { get; set; } = new();
    
    public static AuthValidationErrorResponseDto FromValidationResult(ValidationResult result)
    {
        return new AuthValidationErrorResponseDto
        {
            Errors = result.Errors
                .GroupBy(x => x.PropertyName)
                .ToDictionary(
                    g => g.Key,
                    g => g.Select(x => x.ErrorMessage).ToArray()
                )
        };
    }
}