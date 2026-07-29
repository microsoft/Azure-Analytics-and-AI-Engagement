namespace HcpPortalApi.Application.DTOs;

public sealed record EnrollmentCreatedEvent(
    Guid EnrollmentId,
    string Npi,
    string FirstName,
    string LastName,
    string Email,
    string Specialty,
    string OrganizationName,
    DateTimeOffset CreatedUtc);