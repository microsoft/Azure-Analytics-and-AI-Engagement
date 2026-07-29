namespace HcpPortal.Models;

public class MedicationOrderResponse
{
    public string OrderId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string ClinicalReviewToken { get; set; } = string.Empty;
    public DateTimeOffset SubmittedAtUtc { get; set; }
}
