using HcpPortalApi.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HcpPortalApi.Infrastructure.Persistence.Configurations;

public sealed class PhysicianEnrollmentEntityConfiguration : IEntityTypeConfiguration<PhysicianEnrollment>
{
    public void Configure(EntityTypeBuilder<PhysicianEnrollment> builder)
    {
        builder.ToTable("PhysicianEnrollments");
        builder.HasKey(x => x.Id);

        builder.Property(x => x.Npi)
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(x => x.FirstName)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(x => x.LastName)
            .HasMaxLength(100)
            .IsRequired();

        builder.Property(x => x.Email)
            .HasMaxLength(256)
            .IsRequired();

        builder.Property(x => x.Specialty)
            .HasMaxLength(120)
            .IsRequired();

        builder.Property(x => x.OrganizationName)
            .HasMaxLength(180)
            .IsRequired();

        builder.Property(x => x.Status)
            .IsRequired();

        builder.Property(x => x.CreatedUtc)
            .IsRequired();

        builder.Property(x => x.UpdatedUtc)
            .IsRequired();

        builder.HasIndex(x => x.Npi)
            .HasDatabaseName("IX_PhysicianEnrollments_Npi");
    }
}