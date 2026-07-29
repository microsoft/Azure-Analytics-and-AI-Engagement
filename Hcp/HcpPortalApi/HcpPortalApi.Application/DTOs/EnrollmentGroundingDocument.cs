namespace HcpPortalApi.Application.DTOs;

public sealed record EnrollmentGroundingDocument(
    Guid EnrollmentId,
    string TenantCode,
    string Npi,
    string FirstName,
    string LastName,
    string Email,
    string Specialty,
    string OrganizationName,
    DateTimeOffset CreatedUtc,
    string ContentText,
    float[]? Embedding,
    string? EmbeddingModel);