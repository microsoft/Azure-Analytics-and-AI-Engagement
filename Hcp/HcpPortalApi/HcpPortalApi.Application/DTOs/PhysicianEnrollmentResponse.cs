using HcpPortalApi.Domain.Enums;

namespace HcpPortalApi.Application.DTOs;

public sealed record PhysicianEnrollmentResponse(
    Guid Id,
    string Npi,
    string FirstName,
    string LastName,
    string Email,
    string Specialty,
    string OrganizationName,
    EnrollmentStatus Status,
    DateTimeOffset CreatedUtc,
    DateTimeOffset UpdatedUtc);