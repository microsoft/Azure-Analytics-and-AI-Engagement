using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Domain.Entities;
using HcpPortalApi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace HcpPortalApi.Infrastructure.Repositories;

public sealed class PhysicianEnrollmentRepository : IPhysicianEnrollmentRepository
{
    private readonly HcpPortalDbContext _dbContext;

    public PhysicianEnrollmentRepository(HcpPortalDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(PhysicianEnrollment enrollment, CancellationToken cancellationToken)
    {
        await _dbContext.PhysicianEnrollments.AddAsync(enrollment, cancellationToken);
    }

    public Task<PhysicianEnrollment?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.PhysicianEnrollments
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    }

    public async Task<IReadOnlyList<PhysicianEnrollment>> GetRecentAsync(int limit, CancellationToken cancellationToken)
    {
        return await _dbContext.PhysicianEnrollments
            .AsNoTracking()
            .OrderByDescending(x => x.CreatedUtc)
            .Take(limit)
            .ToListAsync(cancellationToken);
    }

    public Task SaveChangesAsync(CancellationToken cancellationToken)
    {
        return _dbContext.SaveChangesAsync(cancellationToken);
    }
}