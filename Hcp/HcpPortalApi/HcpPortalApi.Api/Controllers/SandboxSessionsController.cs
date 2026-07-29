using HcpPortalApi.Api.Contracts;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using Microsoft.AspNetCore.Mvc;

namespace HcpPortalApi.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class SandboxSessionsController : ControllerBase
{
    private readonly ISandboxSessionService _sessions;
    private readonly ILogger<SandboxSessionsController> _logger;

    public SandboxSessionsController(
        ISandboxSessionService sessions,
        ILogger<SandboxSessionsController> logger)
    {
        _sessions = sessions;
        _logger = logger;
    }

    [HttpPost]
    [ProducesResponseType(typeof(SandboxSession), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(
        [FromBody] CreateSandboxSessionHttpRequest request,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.PrescriberNpi))
        {
            return BadRequest(new { error = "prescriberNpi is required" });
        }

        try
        {
            var session = await _sessions.CreateAsync(request.PrescriberNpi, cancellationToken);
            return CreatedAtAction(nameof(GetById), new { id = session.SessionId }, session);
        }
        catch (Exception ex) when (IsSandboxRuntimeFailure(ex))
        {
            return SandboxUnavailable(ex, "create sandbox session");
        }
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(SandboxSession), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var session = await _sessions.GetAsync(id, cancellationToken);
            return session is null ? NotFound() : Ok(session);
        }
        catch (Exception ex) when (IsSandboxRuntimeFailure(ex))
        {
            return SandboxUnavailable(ex, "get sandbox session");
        }
    }

    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<SandboxSession>), StatusCodes.Status200OK)]
    public async Task<IActionResult> ListActive(CancellationToken cancellationToken)
    {
        try
        {
            var sessions = await _sessions.ListActiveAsync(cancellationToken);
            return Ok(sessions);
        }
        catch (Exception ex) when (IsSandboxRuntimeFailure(ex))
        {
            return SandboxUnavailable(ex, "list sandbox sessions");
        }
    }

    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> End(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var ended = await _sessions.EndAsync(id, cancellationToken);
            return ended ? NoContent() : NotFound();
        }
        catch (Exception ex) when (IsSandboxRuntimeFailure(ex))
        {
            return SandboxUnavailable(ex, "end sandbox session");
        }
    }

    private IActionResult SandboxUnavailable(Exception ex, string operation)
    {
        _logger.LogError(ex, "Failed to {Operation} due to sandbox runtime/configuration failure.", operation);

        return Problem(
            statusCode: StatusCodes.Status503ServiceUnavailable,
            title: "Sandbox service is unavailable.",
            detail: ex.Message);
    }

    private static bool IsSandboxRuntimeFailure(Exception ex)
    {
        return ex is InvalidOperationException or HttpRequestException or TaskCanceledException;
    }
}
