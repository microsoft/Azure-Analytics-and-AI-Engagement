using HcpPortalApi.Domain.Entities;

namespace HcpPortalApi.Application.Abstractions;

public interface IPhysicianEnrollmentRepository
{
    Task AddAsync(PhysicianEnrollment enrollment, CancellationToken cancellationToken);

    Task<PhysicianEnrollment?> GetByIdAsync(Guid id, CancellationToken cancellationToken);

    Task<IReadOnlyList<PhysicianEnrollment>> GetRecentAsync(int limit, CancellationToken cancellationToken);

    Task SaveChangesAsync(CancellationToken cancellationToken);
}