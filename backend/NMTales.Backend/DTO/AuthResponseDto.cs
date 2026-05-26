namespace NMTales.Backend.DTO
{
    public class AuthResponseDto
    {
        public string Message { get; set; } = string.Empty;

        public string Token { get; set; } = string.Empty;

        public UserDto? User { get; set; }
    }
}
