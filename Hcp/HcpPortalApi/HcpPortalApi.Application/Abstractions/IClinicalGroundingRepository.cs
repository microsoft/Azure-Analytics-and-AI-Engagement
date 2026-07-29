using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface IClinicalGroundingRepository
{
    Task SaveEnrollmentGroundingDocumentAsync(EnrollmentGroundingDocument document, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ClinicalGroundingSnippet>> SearchGroundingDocumentsAsync(
        string tenantCode,
        string prescriberNpi,
        float[] embedding,
        int maxCount = 5,
        CancellationToken cancellationToken = default);
}