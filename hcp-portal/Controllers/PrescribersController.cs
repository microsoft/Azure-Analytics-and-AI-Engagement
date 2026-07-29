using HcpPortal.Models;
using HcpPortal.Services;
using Microsoft.AspNetCore.Mvc;

namespace HcpPortal.Controllers;

[ApiController]
[Route("api/[controller]")]
public class PrescribersController : ControllerBase
{
    private readonly IPrescriberService _prescriberService;

    public PrescribersController(IPrescriberService prescriberService)
    {
        _prescriberService = prescriberService;
    }

    [HttpGet("{prescriberId}/profile")]
    public ActionResult<PrescriberProfile> GetProfile(string prescriberId)
    {
        if (string.IsNullOrWhiteSpace(prescriberId))
        {
            return BadRequest("prescriberId is required.");
        }

        return Ok(_prescriberService.GetProfile(prescriberId));
    }

    [HttpPost("orders")]
    public ActionResult<MedicationOrderResponse> SubmitOrder([FromBody] MedicationOrderRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.PatientId) ||
            string.IsNullOrWhiteSpace(request.PrescriberId) ||
            string.IsNullOrWhiteSpace(request.MedicationCode) ||
            request.Quantity <= 0)
        {
            return BadRequest("PatientId, PrescriberId, MedicationCode and Quantity are required.");
        }

        var response = _prescriberService.SubmitOrder(request);
        return Ok(response);
    }
}
