using HcpPortalApi.Api.Contracts;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace HcpPortalApi.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class ClinicianAssistantController : ControllerBase
{
    private readonly IClinicianAssistantService _assistantService;
    private readonly ISandboxAssistantExecutor _sandboxAssistantExecutor;
    private readonly ISandboxSessionService _sandboxSessions;
    private readonly SandboxRuntimeOptions _sandboxRuntimeOptions;
    private readonly ILogger<ClinicianAssistantController> _logger;

    public ClinicianAssistantController(
        IClinicianAssistantService assistantService,
        ISandboxAssistantExecutor sandboxAssistantExecutor,
        ISandboxSessionService sandboxSessions,
        IOptions<SandboxRuntimeOptions> sandboxRuntimeOptions,
        ILogger<ClinicianAssistantController> logger)
    {
        _assistantService = assistantService;
        _sandboxAssistantExecutor = sandboxAssistantExecutor;
        _sandboxSessions = sandboxSessions;
        _sandboxRuntimeOptions = sandboxRuntimeOptions.Value;
        _logger = logger;
    }

    [HttpPost("query")]
    [ProducesResponseType(typeof(ClinicianAnswerResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Query(
        [FromBody] AskClinicianAssistantHttpRequest request,
        CancellationToken cancellationToken)
    {
        var prescriberNpi = request.PrescriberNpi?.Trim() ?? string.Empty;
        var assistantRequest = new ClinicianQuestionRequest(
            request.TenantId,
            prescriberNpi,
            request.Question,
            request.ConversationId);

        if (string.IsNullOrWhiteSpace(prescriberNpi))
        {
            _logger.LogInformation("No prescriber NPI provided. Executing assistant query in shared runtime mode.");
            var sharedResponse = await _assistantService.AnswerAsync(assistantRequest, cancellationToken);
            return Ok(sharedResponse);
        }

        SandboxSession? activeSandbox = null;
        try
        {
            activeSandbox = await _sandboxSessions.GetActiveByPrescriberAsync(prescriberNpi, cancellationToken);
        }
        catch (Exception ex) when (IsSandboxRuntimeFailure(ex))
        {
            if (_sandboxRuntimeOptions.RequireIsolatedSandboxExecution)
            {
                return SandboxUnavailable(ex, "lookup active sandbox session");
            }

            _logger.LogWarning(ex, "Sandbox session lookup failed for prescriber {PrescriberNpi}. Falling back to shared assistant runtime.", prescriberNpi);
        }

        if (activeSandbox is null && _sandboxRuntimeOptions.RequireIsolatedSandboxExecution)
        {
            return Problem(
                statusCode: StatusCodes.Status409Conflict,
                title: "Active sandbox session is required.",
                detail: "Start a sandbox session for this prescriber before querying the assistant.");
        }

        if (activeSandbox is not null)
        {
            try
            {
                var sandboxResponse = await _sandboxAssistantExecutor.ExecuteAsync(assistantRequest, activeSandbox, cancellationToken);
                return Ok(sandboxResponse);
            }
            catch (Exception ex) when (IsSandboxRuntimeFailure(ex))
            {
                if (_sandboxRuntimeOptions.RequireIsolatedSandboxExecution)
                {
                    return SandboxUnavailable(ex, "execute assistant query in sandbox runtime");
                }

                _logger.LogWarning(ex, "Sandbox execution failed for prescriber {PrescriberNpi}. Falling back to shared assistant runtime.", prescriberNpi);
            }
        }

        var response = await _assistantService.AnswerAsync(assistantRequest, cancellationToken);

        return Ok(response);
    }

    private static bool IsSandboxRuntimeFailure(Exception ex)
    {
        return ex is InvalidOperationException or HttpRequestException or TaskCanceledException;
    }

    private IActionResult SandboxUnavailable(Exception ex, string operation)
    {
        _logger.LogError(ex, "Sandbox-isolated execution required, but failed to {Operation}.", operation);

        return Problem(
            statusCode: StatusCodes.Status503ServiceUnavailable,
            title: "Sandbox runtime is unavailable.",
            detail: ex.Message);
    }
}