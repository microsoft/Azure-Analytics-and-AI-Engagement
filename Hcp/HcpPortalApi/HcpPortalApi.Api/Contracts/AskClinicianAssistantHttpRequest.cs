using System.ComponentModel.DataAnnotations;

namespace HcpPortalApi.Api.Contracts;

public sealed class AskClinicianAssistantHttpRequest
{
    [Required]
    [MaxLength(64)]
    public string TenantId { get; init; } = "caldova-hcp";

    [MaxLength(20)]
    public string? PrescriberNpi { get; init; }

    [Required]
    [MaxLength(2000)]
    public string Question { get; init; } = string.Empty;

    [MaxLength(128)]
    public string? ConversationId { get; init; }
}