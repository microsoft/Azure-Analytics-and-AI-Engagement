using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PharmacyLegacy.Models
{
    [Table("Orders")]
    public class Order
    {
        public int Id { get; set; }
        public int PatientId { get; set; }
        [ForeignKey("PatientId")] public virtual Patient Patient { get; set; }
        public DateTime OrderDate { get; set; } = DateTime.UtcNow;
        [StringLength(50)] public string Status { get; set; } = "Pending";
        [Column(TypeName = "decimal(18,2)")] public decimal TotalAmount { get; set; }
        [StringLength(500)] public string DeliveryAddress { get; set; }
        public bool PrescriptionVerified { get; set; }

        public virtual ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    }

    [Table("OrderItems")]
    public class OrderItem
    {
        public int Id { get; set; }
        public int OrderId { get; set; }
        [ForeignKey("OrderId")] public virtual Order Order { get; set; }
        public int MedicationId { get; set; }
        [ForeignKey("MedicationId")] public virtual Medication Medication { get; set; }
        public int Quantity { get; set; }
        [Column(TypeName = "decimal(18,2)")] public decimal UnitPrice { get; set; }
    }
}
