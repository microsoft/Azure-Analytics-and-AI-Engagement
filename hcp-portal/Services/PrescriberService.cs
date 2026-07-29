using HcpPortal.Models;

namespace HcpPortal.Services;

public class PrescriberService : IPrescriberService
{
    private readonly IConfiguration _configuration;

    public PrescriberService(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public PrescriberProfile GetProfile(string prescriberId)
    {
        return new PrescriberProfile
        {
            PrescriberId = prescriberId,
            Npi = "1234567890",
            FullName = "Dr. Sam Carter",
            Specialty = "Internal Medicine",
            ClinicName = "ABC Pharma Affiliated Care"
        };
    }

    public MedicationOrderResponse SubmitOrder(MedicationOrderRequest request)
    {
        var apiBase = _configuration[HcpPortalConfiguration.Patient360BaseUrlKey] ?? "https://patient360.internal";
        var credential = _configuration[HcpPortalConfiguration.Patient360CredentialKey];

        if (string.IsNullOrWhiteSpace(credential))
        {
            throw new InvalidOperationException("Patient360 downstream credential is missing.");
        }

        // In production this would call the downstream patient service using apiBase/credential.
        return new MedicationOrderResponse
        {
            OrderId = $"rx-{Guid.NewGuid():N}"[..13],
            Status = "Accepted",
            ClinicalReviewToken = Convert.ToBase64String(Guid.NewGuid().ToByteArray()),
            SubmittedAtUtc = DateTimeOffset.UtcNow
        };
    }
}
