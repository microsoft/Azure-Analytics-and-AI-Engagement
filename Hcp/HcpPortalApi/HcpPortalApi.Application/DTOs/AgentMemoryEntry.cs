namespace HcpPortalApi.Application.DTOs;

public sealed record AgentMemoryEntry
{
    public string Id { get; init; } = Guid.NewGuid().ToString();

    /// <summary>Partition key — format: {tenantId}|{principalId}</summary>
    public string MemoryKey { get; init; } = string.Empty;

    public string TenantId { get; init; } = string.Empty;
    public string PrincipalId { get; init; } = string.Empty;
    public string MemoryType { get; init; } = "summary";
    public string? SourceConversationId { get; init; }

    /// <summary>Importance score 0.0–1.0 used for retrieval ranking.</summary>
    public double Importance { get; init; } = 0.5;

    public string Summary { get; init; } = string.Empty;
    public string[] Tags { get; init; } = [];
    public DateTimeOffset CreatedUtc { get; init; } = DateTimeOffset.UtcNow;
    public DateTimeOffset UpdatedUtc { get; init; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? ExpiresUtc { get; init; }
}
