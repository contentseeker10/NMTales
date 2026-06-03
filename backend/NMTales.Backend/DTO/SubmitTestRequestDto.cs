namespace NMTales.Backend.DTO
{
    /// <summary>
    /// Single submit shape for both test kinds. The server dispatches on the session's
    /// subject: math reads <see cref="AnswerId"/>, the Ukrainian scroll reads <see cref="Slots"/>.
    /// </summary>
    public class SubmitTestRequestDto
    {
        public int SessionId { get; set; }

        // Math: the chosen answer's id.
        public int? AnswerId { get; set; }

        // Ukrainian (Drag & Drop): which answer was dropped into which slot.
        public List<SlotSubmissionDto>? Slots { get; set; }
    }

    public class SlotSubmissionDto
    {
        public int SlotIndex { get; set; }
        public int AnswerId { get; set; }
    }
}
