namespace HcpPortalApi.Application.DTOs;

public sealed record ClinicianQuestionRequest(
    string TenantId,
    string PrescriberNpi,
    string Question,
    string? ConversationId);