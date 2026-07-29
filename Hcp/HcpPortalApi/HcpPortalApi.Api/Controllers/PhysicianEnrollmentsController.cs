using HcpPortalApi.Api.Contracts;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace HcpPortalApi.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class PhysicianEnrollmentsController : ControllerBase
{
    private readonly IPhysicianEnrollmentService _enrollmentService;

    public PhysicianEnrollmentsController(IPhysicianEnrollmentService enrollmentService)
    {
        _enrollmentService = enrollmentService;
    }

    [HttpPost]
    [ProducesResponseType(typeof(PhysicianEnrollmentResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(
        [FromBody] CreatePhysicianEnrollmentHttpRequest request,
        CancellationToken cancellationToken)
    {
        var command = new CreatePhysicianEnrollmentRequest(
            request.Npi,
            request.FirstName,
            request.LastName,
            request.Email,
            request.Specialty,
            request.OrganizationName);

        var response = await _enrollmentService.EnrollAsync(command, cancellationToken);

        return CreatedAtAction(nameof(GetById), new { id = response.Id }, response);
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(PhysicianEnrollmentResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        var response = await _enrollmentService.GetByIdAsync(id, cancellationToken);
        return response is null ? NotFound() : Ok(response);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<PhysicianEnrollmentResponse>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetRecent([FromQuery] int limit = 10, CancellationToken cancellationToken = default)
    {
        var normalizedLimit = Math.Clamp(limit, 1, 25);
        var response = await _enrollmentService.GetRecentAsync(normalizedLimit, cancellationToken);
        return Ok(response);
    }
}
