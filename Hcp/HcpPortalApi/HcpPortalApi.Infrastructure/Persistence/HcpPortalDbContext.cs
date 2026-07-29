using HcpPortalApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace HcpPortalApi.Infrastructure.Persistence;

public sealed class HcpPortalDbContext : DbContext
{
    public HcpPortalDbContext(DbContextOptions<HcpPortalDbContext> options)
        : base(options)
    {
    }

    public DbSet<PhysicianEnrollment> PhysicianEnrollments => Set<PhysicianEnrollment>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(HcpPortalDbContext).Assembly);
        base.OnModelCreating(modelBuilder);
    }
}