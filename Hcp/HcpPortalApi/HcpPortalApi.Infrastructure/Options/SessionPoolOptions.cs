namespace HcpPortalApi.Infrastructure.Options;

public sealed class SessionPoolOptions
{
    public const string SectionName = "SessionPool";

    /// <summary>
    /// Base management endpoint for the Session Pool data plane.
    /// Example: https://eastus.dynamicsessions.io/subscriptions/.../sessionPools/hcp-sess-xxxx
    /// </summary>
    public string? ManagementEndpoint { get; init; }

    /// <summary>AAD audience/scope for Session Pool operations.</summary>
    public string Audience { get; init; } = "https://dynamicsessions.io/.default";

    /// <summary>API version for Session Pool data-plane calls.</summary>
    public string ApiVersion { get; init; } = "2025-02-02-preview";

    /// <summary>
    /// Python code used for a lightweight warm-up execution that creates/activates a session.
    /// Keep this side-effect free.
    /// </summary>
    public string WarmupCode { get; init; } = "print('session-ready')";

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ManagementEndpoint);
}
