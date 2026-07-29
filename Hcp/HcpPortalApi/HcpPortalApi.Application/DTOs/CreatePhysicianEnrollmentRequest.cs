namespace HcpPortalApi.Application.DTOs;

public sealed record CreatePhysicianEnrollmentRequest(
    string Npi,
    string FirstName,
    string LastName,
    string Email,
    string Specialty,
    string OrganizationName);