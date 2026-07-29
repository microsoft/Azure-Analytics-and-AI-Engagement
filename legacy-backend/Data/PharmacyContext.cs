using System.Data.Entity;
using PharmacyLegacy.Models;

namespace PharmacyLegacy.Data
{
    public class PharmacyContext : DbContext
    {
        public PharmacyContext()
            : base(System.Environment.GetEnvironmentVariable("PHARMACY_DB_CONNSTR") ?? "name=PharmacyContext") { }

        public DbSet<Medication> Medications { get; set; }
        public DbSet<Patient>    Patients    { get; set; }
        public DbSet<Order>      Orders      { get; set; }
        public DbSet<OrderItem>  OrderItems  { get; set; }
        public DbSet<Inventory>  Inventories { get; set; }

        protected override void OnModelCreating(DbModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Patient>()
                .HasMany(p => p.Orders)
                .WithRequired(o => o.Patient)
                .HasForeignKey(o => o.PatientId)
                .WillCascadeOnDelete(true);

            modelBuilder.Entity<Order>()
                .HasMany(o => o.Items)
                .WithRequired(oi => oi.Order)
                .HasForeignKey(oi => oi.OrderId)
                .WillCascadeOnDelete(true);
        }
    }
}
