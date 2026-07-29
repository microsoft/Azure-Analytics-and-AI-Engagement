using HcpPortal.Models;
using HcpPortal.Services;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace HcpPortal.Tests.Unit;

public class PrescriberServiceTests
{
    [Fact]
    public void GetProfile_ReturnsExpectedProfile()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                [HcpPortalConfiguration.Patient360CredentialKey] = "unit-test-credential"
            })
            .Build();

        var service = new PrescriberService(config);

        var profile = service.GetProfile("hcp-001");

        Assert.Equal("hcp-001", profile.PrescriberId);
        Assert.Equal("Dr. Sam Carter", profile.FullName);
        Assert.False(string.IsNullOrWhiteSpace(profile.Specialty));
    }

    [Fact]
    public void SubmitOrder_ReturnsAcceptedResponse_WhenCredentialConfigured()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                [HcpPortalConfiguration.Patient360CredentialKey] = "unit-test-credential",
                [HcpPortalConfiguration.Patient360BaseUrlKey] = "https://patient360.test"
            })
            .Build();

        var service = new PrescriberService(config);

        var response = service.SubmitOrder(new MedicationOrderRequest
        {
            PatientId = "p-100",
            PrescriberId = "hcp-001",
            MedicationCode = "ATV-20",
            Quantity = 30,
            Refills = 2,
            Directions = "Take one tablet daily"
        });

        Assert.Equal("Accepted", response.Status);
        Assert.StartsWith("rx-", response.OrderId);
        Assert.NotEqual(default, response.SubmittedAtUtc);
    }
}
