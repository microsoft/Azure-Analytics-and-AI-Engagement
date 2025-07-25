using System.Collections.Generic;

namespace PartsUnitBacked.Models
{
    public class Cart
    {
        public int Id { get; set; }
        public string UserId { get; set; } = string.Empty;
        public List<CartItem> Items { get; set; } = new List<CartItem>();
    }
} 