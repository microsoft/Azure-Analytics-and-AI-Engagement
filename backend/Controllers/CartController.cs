using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PartsUnitBacked.Data;
using PartsUnitBacked.Models;

namespace PartsUnitBacked.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class CartController : ControllerBase
    {
        private readonly AppDbContext _context;
        public CartController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/cart/{userId}
        [HttpGet("{userId}")]
        public async Task<ActionResult<Cart>> GetCart(string userId)
        {
            var cart = await _context.Carts.Include(c => c.Items).ThenInclude(i => i.Product)
                .FirstOrDefaultAsync(c => c.UserId == userId);
            if (cart == null)
            {
                cart = new Cart { UserId = userId };
                _context.Carts.Add(cart);
                await _context.SaveChangesAsync();
            }
            return cart;
        }

        // POST: api/cart/{userId}/add
        [HttpPost("{userId}/add")]
        public async Task<IActionResult> AddToCart(string userId, [FromBody] CartItem item)
        {
            var cart = await _context.Carts.Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.UserId == userId);
            if (cart == null)
            {
                cart = new Cart { UserId = userId };
                _context.Carts.Add(cart);
            }
            var existingItem = cart.Items.FirstOrDefault(i => i.ProductId == item.ProductId);
            if (existingItem != null)
            {
                existingItem.Quantity += item.Quantity;
            }
            else
            {
                cart.Items.Add(new CartItem { ProductId = item.ProductId, Quantity = item.Quantity });
            }
            await _context.SaveChangesAsync();
            return Ok(cart);
        }

        // POST: api/cart/{userId}/update
        [HttpPost("{userId}/update")]
        public async Task<IActionResult> UpdateCartItem(string userId, [FromBody] CartItem item)
        {
            var cart = await _context.Carts.Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.UserId == userId);
            if (cart == null) return NotFound();
            var existingItem = cart.Items.FirstOrDefault(i => i.ProductId == item.ProductId);
            if (existingItem == null) return NotFound();
            existingItem.Quantity = item.Quantity;
            await _context.SaveChangesAsync();
            return Ok(cart);
        }

        // POST: api/cart/{userId}/remove
        [HttpPost("{userId}/remove")]
        public async Task<IActionResult> RemoveFromCart(string userId, [FromBody] int productId)
        {
            var cart = await _context.Carts.Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.UserId == userId);
            if (cart == null) return NotFound();
            var item = cart.Items.FirstOrDefault(i => i.ProductId == productId);
            if (item == null) return NotFound();
            cart.Items.Remove(item);
            await _context.SaveChangesAsync();
            return Ok(cart);
        }
    }
} 