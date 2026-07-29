using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using PharmacyBackend.Data;

#nullable disable

namespace PharmacyBackend.Migrations
{
    [DbContext(typeof(AppDbContext))]
    [Migration("20250623151229_InitialCreate")]
    partial class InitialCreate
    {
        protected override void BuildTargetModel(ModelBuilder modelBuilder) { }
    }
}
