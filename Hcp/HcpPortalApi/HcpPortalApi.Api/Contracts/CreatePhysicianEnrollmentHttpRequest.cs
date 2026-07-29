using System.ComponentModel.DataAnnotations;

namespace HcpPortalApi.Api.Contracts;

public sealed class CreatePhysicianEnrollmentHttpRequest
{
    [Required]
    [MaxLength(20)]
    public string Npi { get; init; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string FirstName { get; init; } = string.Empty;

    [Required]
    [MaxLength(100)]
    public string LastName { get; init; } = string.Empty;

    [Required]
    [EmailAddress]
    [MaxLength(256)]
    public string Email { get; init; } = string.Empty;

    [Required]
    [MaxLength(120)]
    public string Specialty { get; init; } = string.Empty;

    [Required]
    [MaxLength(180)]
    public string OrganizationName { get; init; } = string.Empty;
}
