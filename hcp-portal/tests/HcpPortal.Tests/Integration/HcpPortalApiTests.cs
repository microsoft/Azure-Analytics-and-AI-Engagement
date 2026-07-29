using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Xunit;

namespace HcpPortal.Tests.Integration;

public class HcpPortalApiTests : IClassFixture<WebApplicationFactory<Program>>, IDisposable
{
    private readonly WebApplicationFactory<Program> _factory;

    public HcpPortalApiTests(WebApplicationFactory<Program> factory)
    {
        Environment.SetEnvironmentVariable("DownstreamApis__Patient360Credential", "integration-test-credential");
        Environment.SetEnvironmentVariable("DownstreamApis__Patient360BaseUrl", "https://patient360.integration");
        Environment.SetEnvironmentVariable("AZURE_KEYVAULT_URI", "");
        Environment.SetEnvironmentVariable("AZURE_APPCONFIG_ENDPOINT", "");

        _factory = factory;
    }

    public void Dispose()
    {
        Environment.SetEnvironmentVariable("DownstreamApis__Patient360Credential", null);
        Environment.SetEnvironmentVariable("DownstreamApis__Patient360BaseUrl", null);
        Environment.SetEnvironmentVariable("AZURE_KEYVAULT_URI", null);
        Environment.SetEnvironmentVariable("AZURE_APPCONFIG_ENDPOINT", null);
    }

    [Fact]
    public async Task PrescriberLookup_ReturnsExpectedProfile()
    {
        using var client = _factory.CreateClient();

        var response = await client.GetAsync("/api/prescribers/hcp-900/profile");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(payload);
        Assert.Equal("hcp-900", payload!["prescriberId"]?.ToString());
        Assert.Equal("Dr. Sam Carter", payload["fullName"]?.ToString());
    }

    [Fact]
    public async Task PrescriptionSubmission_ReturnsAcceptedOrder()
    {
        using var client = _factory.CreateClient();

        var request = new
        {
            patientId = "p-314",
            prescriberId = "hcp-900",
            medicationCode = "AMOX-500",
            medicationName = "Amoxicillin",
            strength = "500mg",
            directions = "Take one capsule twice daily",
            quantity = 20,
            refills = 1
        };

        var response = await client.PostAsJsonAsync("/api/prescribers/orders", request);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadFromJsonAsync<Dictionary<string, object>>();
        Assert.NotNull(payload);
        Assert.Equal("Accepted", payload!["status"]?.ToString());
        Assert.StartsWith("rx-", payload["orderId"]?.ToString());
    }
}
