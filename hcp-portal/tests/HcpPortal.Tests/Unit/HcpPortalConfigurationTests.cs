using HcpPortal;
using Xunit;

namespace HcpPortal.Tests.Unit;

public class HcpPortalConfigurationTests
{
    [Fact]
    public void TryAddAzureKeyVault_ReturnsFalse_WhenUriMissing()
    {
        var wasCalled = false;

        var result = HcpPortalConfiguration.TryAddAzureKeyVault(
            null,
            _ =>
            {
                wasCalled = true;
                return true;
            });

        Assert.False(result);
        Assert.False(wasCalled);
    }

    [Fact]
    public void TryAddAzureKeyVault_InvokesProvider_WhenUriPresent()
    {
        Uri? resolvedUri = null;

        var result = HcpPortalConfiguration.TryAddAzureKeyVault(
            "https://abc-kv.vault.azure.net/",
            uri =>
            {
                resolvedUri = uri;
                return true;
            });

        Assert.True(result);
        Assert.NotNull(resolvedUri);
        Assert.Equal("https://abc-kv.vault.azure.net/", resolvedUri!.ToString());
    }

    [Fact]
    public void TryAddAzureKeyVault_Throws_WhenUriInvalid()
    {
        Assert.Throws<InvalidOperationException>(() =>
            HcpPortalConfiguration.TryAddAzureKeyVault("not-a-uri", _ => true));
    }
}
