using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PharmacyLegacy.Models
{
    [Table("Medications")]
    public class Medication
    {
        public int Id { get; set; }
        [Required, StringLength(200)] public string Name { get; set; }
        [StringLength(200)]           public string GenericName { get; set; }
        [Required, StringLength(100)] public string Category { get; set; }
        [StringLength(100)]           public string DosageForm { get; set; }
        [StringLength(50)]            public string Strength { get; set; }
        [StringLength(200)]           public string Manufacturer { get; set; }
        [StringLength(1000)]          public string Description { get; set; }
        [Column(TypeName = "decimal(18,2)")] public decimal Price { get; set; }
        public int Stock { get; set; }
        public bool RequiresPrescription { get; set; }
        [StringLength(500)] public string ImageUrl { get; set; }
    }
}
