using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface IPhysicianEnrollmentService
{
    Task<PhysicianEnrollmentResponse> EnrollAsync(CreatePhysicianEnrollmentRequest request, CancellationToken cancellationToken);

    Task<PhysicianEnrollmentResponse?> GetByIdAsync(Guid id, CancellationToken cancellationToken);

    Task<IReadOnlyList<PhysicianEnrollmentResponse>> GetRecentAsync(int limit, CancellationToken cancellationToken);
}