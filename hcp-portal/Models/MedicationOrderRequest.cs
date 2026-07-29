namespace HcpPortal.Models;

public class MedicationOrderRequest
{
    public string PatientId { get; set; } = string.Empty;
    public string PrescriberId { get; set; } = string.Empty;
    public string MedicationCode { get; set; } = string.Empty;
    public string MedicationName { get; set; } = string.Empty;
    public string Strength { get; set; } = string.Empty;
    public string Directions { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public int Refills { get; set; }
}
