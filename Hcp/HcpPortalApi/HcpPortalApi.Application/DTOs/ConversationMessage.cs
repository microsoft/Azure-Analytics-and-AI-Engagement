namespace HcpPortalApi.Application.DTOs;

public sealed record ConversationMessage
{
    public string Id { get; init; } = Guid.NewGuid().ToString();

    /// <summary>Partition key — format: {tenantId}|{conversationId}</summary>
    public string ConversationKey { get; init; } = string.Empty;

    public string ConversationId { get; init; } = string.Empty;
    public string TenantId { get; init; } = string.Empty;
    public int Sequence { get; init; }
    public string Role { get; init; } = string.Empty;
    public string Content { get; init; } = string.Empty;
    public string? SourceSystem { get; init; }
    public Dictionary<string, string>? Metadata { get; init; }
    public DateTimeOffset CreatedUtc { get; init; } = DateTimeOffset.UtcNow;

    /// <summary>TTL in seconds — 90 days default, matching the Cosmos container TTL.</summary>
    public int Ttl { get; init; } = 7_776_000;
}
