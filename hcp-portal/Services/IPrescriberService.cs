using HcpPortal.Models;

namespace HcpPortal.Services;

public interface IPrescriberService
{
    PrescriberProfile GetProfile(string prescriberId);
    MedicationOrderResponse SubmitOrder(MedicationOrderRequest request);
}
