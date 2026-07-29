namespace HcpPortalApi.Application.DTOs;

public sealed record SandboxSession(
    Guid SessionId,
    string PrescriberNpi,
    string SandboxId,
    string SandboxGroupName,
    string ManagementEndpoint,
    string Status,
    DateTimeOffset CreatedAt,
    DateTimeOffset? EndedAt);
