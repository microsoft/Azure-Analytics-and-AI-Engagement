using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using PartsUnitBacked.Data;
using PartsUnitBacked.Models;

namespace PartsUnitBacked.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ProductsController : ControllerBase
    {
        private readonly AppDbContext _context;
        public ProductsController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/products
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Product>>> GetProducts(
            [FromQuery] string? category,
            [FromQuery] string? search,
            [FromQuery] string? sortBy,
            [FromQuery] string? sortOrder,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = _context.Products.AsQueryable();
            if (!string.IsNullOrEmpty(category))
                query = query.Where(p => p.Category.ToLower() == category.ToLower());
            if (!string.IsNullOrEmpty(search))
                query = query.Where(p => p.Name.ToLower().Contains(search.ToLower()) || p.Description.ToLower().Contains(search.ToLower()));

            // Sorting
            bool descending = string.Equals(sortOrder, "desc", StringComparison.OrdinalIgnoreCase);
            switch (sortBy?.ToLower())
            {
                case "name":
                    query = descending ? query.OrderByDescending(p => p.Name) : query.OrderBy(p => p.Name);
                    break;
                case "price":
                    query = descending ? query.OrderByDescending(p => p.Price) : query.OrderBy(p => p.Price);
                    break;
                case "stock":
                    query = descending ? query.OrderByDescending(p => p.Stock) : query.OrderBy(p => p.Stock);
                    break;
                default:
                    query = descending ? query.OrderByDescending(p => p.Id) : query.OrderBy(p => p.Id);
                    break;
            }

            // Pagination
            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;
            var pagedProducts = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
            return pagedProducts;
        }

        // GET: api/products/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<Product>> GetProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();
            return product;
        }

        // POST: api/products
        [HttpPost]
        public async Task<ActionResult<Product>> CreateProduct(Product product)
        {
            _context.Products.Add(product);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
        }

        // PUT: api/products/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateProduct(int id, Product product)
        {
            if (id != product.Id) return BadRequest();
            _context.Entry(product).State = EntityState.Modified;
            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!_context.Products.Any(e => e.Id == id))
                    return NotFound();
                else
                    throw;
            }
            return NoContent();
        }

        // DELETE: api/products/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteProduct(int id)
        {
            var product = await _context.Products.FindAsync(id);
            if (product == null) return NotFound();
            _context.Products.Remove(product);
            await _context.SaveChangesAsync();
            return NoContent();
        }
    }
} 