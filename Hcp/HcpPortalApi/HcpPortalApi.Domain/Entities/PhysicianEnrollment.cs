using HcpPortalApi.Domain.Enums;

namespace HcpPortalApi.Domain.Entities;

public sealed class PhysicianEnrollment
{
    private PhysicianEnrollment()
    {
    }

    public Guid Id { get; private set; }

    public string Npi { get; private set; } = string.Empty;

    public string FirstName { get; private set; } = string.Empty;

    public string LastName { get; private set; } = string.Empty;

    public string Email { get; private set; } = string.Empty;

    public string Specialty { get; private set; } = string.Empty;

    public string OrganizationName { get; private set; } = string.Empty;

    public EnrollmentStatus Status { get; private set; }

    public DateTimeOffset CreatedUtc { get; private set; }

    public DateTimeOffset UpdatedUtc { get; private set; }

    public static PhysicianEnrollment Create(
        string npi,
        string firstName,
        string lastName,
        string email,
        string specialty,
        string organizationName)
    {
        ValidateRequired(npi, nameof(npi));
        ValidateRequired(firstName, nameof(firstName));
        ValidateRequired(lastName, nameof(lastName));
        ValidateRequired(email, nameof(email));
        ValidateRequired(specialty, nameof(specialty));
        ValidateRequired(organizationName, nameof(organizationName));

        var now = DateTimeOffset.UtcNow;

        return new PhysicianEnrollment
        {
            Id = Guid.NewGuid(),
            Npi = npi.Trim(),
            FirstName = firstName.Trim(),
            LastName = lastName.Trim(),
            Email = email.Trim(),
            Specialty = specialty.Trim(),
            OrganizationName = organizationName.Trim(),
            Status = EnrollmentStatus.Pending,
            CreatedUtc = now,
            UpdatedUtc = now
        };
    }

    public void Approve()
    {
        Status = EnrollmentStatus.Approved;
        UpdatedUtc = DateTimeOffset.UtcNow;
    }

    public void Reject()
    {
        Status = EnrollmentStatus.Rejected;
        UpdatedUtc = DateTimeOffset.UtcNow;
    }

    private static void ValidateRequired(string value, string fieldName)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException($"{fieldName} is required.", fieldName);
        }
    }
}