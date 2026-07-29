using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace PharmacyLegacy.Models
{
    [Table("Patients")]
    public class Patient
    {
        public int Id { get; set; }
        [Required, StringLength(100)] public string FirstName { get; set; }
        [Required, StringLength(100)] public string LastName { get; set; }
        [Required, StringLength(255), EmailAddress] public string Email { get; set; }
        [StringLength(20)]  public string Phone { get; set; }
        [StringLength(300)] public string Address { get; set; }
        [StringLength(100)] public string City { get; set; }
        [StringLength(50)]  public string State { get; set; }
        [StringLength(20)]  public string ZipCode { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        public virtual ICollection<Order> Orders { get; set; } = new List<Order>();
    }
}
