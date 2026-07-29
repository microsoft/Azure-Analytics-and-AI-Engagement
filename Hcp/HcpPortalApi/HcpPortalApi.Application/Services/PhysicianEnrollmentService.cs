using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Domain.Entities;
using Microsoft.Extensions.Logging;

namespace HcpPortalApi.Application.Services;

public sealed class PhysicianEnrollmentService : IPhysicianEnrollmentService
{
    private readonly IPhysicianEnrollmentRepository _repository;
    private readonly IEnrollmentEventPublisher _eventPublisher;
    private readonly ILogger<PhysicianEnrollmentService> _logger;

    public PhysicianEnrollmentService(
        IPhysicianEnrollmentRepository repository,
        IEnrollmentEventPublisher eventPublisher,
        ILogger<PhysicianEnrollmentService> logger)
    {
        _repository = repository;
        _eventPublisher = eventPublisher;
        _logger = logger;
    }

    public async Task<PhysicianEnrollmentResponse> EnrollAsync(
        CreatePhysicianEnrollmentRequest request,
        CancellationToken cancellationToken)
    {
        var enrollment = PhysicianEnrollment.Create(
            request.Npi,
            request.FirstName,
            request.LastName,
            request.Email,
            request.Specialty,
            request.OrganizationName);

        await _repository.AddAsync(enrollment, cancellationToken);
        await _repository.SaveChangesAsync(cancellationToken);

        var enrollmentCreatedEvent = new EnrollmentCreatedEvent(
            enrollment.Id,
            enrollment.Npi,
            enrollment.FirstName,
            enrollment.LastName,
            enrollment.Email,
            enrollment.Specialty,
            enrollment.OrganizationName,
            enrollment.CreatedUtc);

        try
        {
            await _eventPublisher.PublishEnrollmentCreatedAsync(enrollmentCreatedEvent, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Enrollment {EnrollmentId} persisted, but publishing enrollment-created event failed.",
                enrollment.Id);
        }

        return MapToResponse(enrollment);
    }

    public async Task<PhysicianEnrollmentResponse?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        var enrollment = await _repository.GetByIdAsync(id, cancellationToken);
        return enrollment is null ? null : MapToResponse(enrollment);
    }

    public async Task<IReadOnlyList<PhysicianEnrollmentResponse>> GetRecentAsync(int limit, CancellationToken cancellationToken)
    {
        var enrollments = await _repository.GetRecentAsync(limit, cancellationToken);
        return enrollments.Select(MapToResponse).ToArray();
    }

    private static PhysicianEnrollmentResponse MapToResponse(PhysicianEnrollment enrollment)
    {
        return new PhysicianEnrollmentResponse(
            enrollment.Id,
            enrollment.Npi,
            enrollment.FirstName,
            enrollment.LastName,
            enrollment.Email,
            enrollment.Specialty,
            enrollment.OrganizationName,
            enrollment.Status,
            enrollment.CreatedUtc,
            enrollment.UpdatedUtc);
    }
}