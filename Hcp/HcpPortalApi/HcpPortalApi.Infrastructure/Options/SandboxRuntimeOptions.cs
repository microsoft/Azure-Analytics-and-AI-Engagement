namespace HcpPortalApi.Infrastructure.Options;

public sealed class SandboxRuntimeOptions
{
    public const string SectionName = "SandboxRuntime";

    /// <summary>
    /// Base URL template for sandbox runtime calls. Supports {sandboxId} and {sandboxGroup} placeholders.
    /// Example: https://{sandboxId}.sandbox-runtime.contoso.internal
    /// </summary>
    public string? BaseUrlTemplate { get; init; }

    /// <summary>Relative path for assistant query execution in sandbox runtime.</summary>
    public string AssistantQueryPath { get; init; } = "/api/assistant/query";

    /// <summary>Optional audience/scope when sandbox runtime requires AAD bearer tokens.</summary>
    public string? Audience { get; init; }

    /// <summary>
    /// When true, assistant queries must execute only in per-session sandbox runtimes.
    /// Any sandbox lookup/execution failure returns an error instead of falling back to shared runtime.
    /// </summary>
    public bool RequireIsolatedSandboxExecution { get; init; } = false;
}
