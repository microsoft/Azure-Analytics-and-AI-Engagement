using Microsoft.EntityFrameworkCore;
using PharmacyBackend.Models;

namespace PharmacyBackend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<Medication> Medications => Set<Medication>();
    }
}
