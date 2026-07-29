namespace HcpPortal;

internal static class HcpPortalConfiguration
{
    internal const string DownstreamApisSection = "DownstreamApis";
    internal const string Patient360CredentialKey = "DownstreamApis:Patient360Credential";
    internal const string Patient360BaseUrlKey = "DownstreamApis:Patient360BaseUrl";

    internal static bool TryAddAzureKeyVault(string? keyVaultUri, Func<Uri, bool> addKeyVaultProvider)
    {
        if (string.IsNullOrWhiteSpace(keyVaultUri))
        {
            return false;
        }

        if (!Uri.TryCreate(keyVaultUri, UriKind.Absolute, out var parsedUri))
        {
            throw new InvalidOperationException(
                "AZURE_KEYVAULT_URI is not a valid absolute URI.");
        }

        return addKeyVaultProvider(parsedUri);
    }
}
