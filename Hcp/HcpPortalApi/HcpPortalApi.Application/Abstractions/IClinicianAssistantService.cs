using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface IClinicianAssistantService
{
    Task<ClinicianAnswerResponse> AnswerAsync(ClinicianQuestionRequest request, CancellationToken cancellationToken);
}