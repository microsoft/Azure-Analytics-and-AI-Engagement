namespace HcpPortalApi.Infrastructure.Options;

public sealed class SandboxGroupOptions
{
    public const string SectionName = "SandboxGroup";

    /// <summary>Name of the pre-provisioned Microsoft.App/sandboxGroups resource.</summary>
    public string? Name { get; init; }

    /// <summary>Data-plane management endpoint returned by the sandbox group (e.g. https://management.centralus.azuredevcompute.io).</summary>
    public string? ManagementEndpoint { get; init; }

    /// <summary>API version used by the ACA Sandboxes data-plane API.</summary>
    public string ApiVersion { get; init; } = "2026-02-01-preview";

    /// <summary>AAD token audience/scope for the ACA Sandboxes data-plane API.</summary>
    public string Audience { get; init; } = "https://management.core.windows.net/.default";

    /// <summary>Relative create/list path template with {group} placeholder.</summary>
    public string CollectionPathTemplate { get; init; } = "/sandboxGroups/{group}/sandboxes";

    /// <summary>Relative item path template with {group} and {sandboxId} placeholders.</summary>
    public string ItemPathTemplate { get; init; } = "/sandboxGroups/{group}/sandboxes/{sandboxId}";
}
