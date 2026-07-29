using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface ISandboxAssistantExecutor
{
    Task<ClinicianAnswerResponse> ExecuteAsync(
        ClinicianQuestionRequest request,
        SandboxSession session,
        CancellationToken cancellationToken);
}
