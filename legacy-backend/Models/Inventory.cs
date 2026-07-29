using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PharmacyLegacy.Models
{
    [Table("Inventory")]
    public class Inventory
    {
        public int Id { get; set; }
        public int MedicationId { get; set; }
        [ForeignKey("MedicationId")] public virtual Medication Medication { get; set; }
        public int QuantityOnHand { get; set; }
        public int ReorderLevel { get; set; }
        public int ReorderQuantity { get; set; }
        [StringLength(50)] public string StorageLocation { get; set; }
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    }
}
