using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;
using PharmacyBackend.Data;
using PharmacyBackend.Models;

namespace PharmacyBackend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MedicationsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly IDistributedCache _cache;

        public MedicationsController(AppDbContext context, IDistributedCache cache)
        {
            _context = context;
            _cache = cache;
        }

        // GET: api/medications
        [HttpGet]
        public async Task<ActionResult<IEnumerable<Medication>>> GetMedications(
            [FromQuery] string? category,
            [FromQuery] string? search,
            [FromQuery] string? sortBy,
            [FromQuery] string? sortOrder,
            [FromQuery] int page = 1,
            [FromQuery] int pageSize = 10)
        {
            string version = await GetListVersionAsync();
            string cacheKey = $"meds-list:v{version}:cat:{category ?? "all"}:q:{search ?? "all"}:sort:{sortBy ?? "default"}:{sortOrder ?? "asc"}:p:{page}:{pageSize}";

            try
            {
                var cachedData = await _cache.GetStringAsync(cacheKey);
                if (!string.IsNullOrEmpty(cachedData))
                {
                    var fromCache = JsonSerializer.Deserialize<List<Medication>>(cachedData);
                    if (fromCache != null) return fromCache;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Redis read error: {ex.Message}");
            }

            var query = _context.Medications.AsQueryable();

            if (!string.IsNullOrEmpty(category))
                query = query.Where(m => m.Category.ToLower() == category.ToLower());

            if (!string.IsNullOrEmpty(search))
                query = query.Where(m => m.Name.ToLower().Contains(search.ToLower())
                                      || m.GenericName.ToLower().Contains(search.ToLower())
                                      || m.Description.ToLower().Contains(search.ToLower()));

            bool descending = string.Equals(sortOrder, "desc", StringComparison.OrdinalIgnoreCase);
            query = sortBy?.ToLower() switch
            {
                "name" => descending ? query.OrderByDescending(m => m.Name) : query.OrderBy(m => m.Name),
                "price" => descending ? query.OrderByDescending(m => m.Price) : query.OrderBy(m => m.Price),
                "stock" => descending ? query.OrderByDescending(m => m.Stock) : query.OrderBy(m => m.Stock),
                _ => descending ? query.OrderByDescending(m => m.Id) : query.OrderBy(m => m.Id)
            };

            if (page < 1) page = 1;
            if (pageSize < 1) pageSize = 10;
            var result = await query.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();

            try
            {
                var opts = new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10) };
                await _cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(result), opts);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Redis write error: {ex.Message}");
            }

            return result;
        }

        // GET: api/medications/{id}
        [HttpGet("{id}")]
        public async Task<ActionResult<Medication>> GetMedication(int id)
        {
            string cacheKey = $"med:{id}";
            try
            {
                var cached = await _cache.GetStringAsync(cacheKey);
                if (!string.IsNullOrEmpty(cached))
                {
                    var fromCache = JsonSerializer.Deserialize<Medication>(cached);
                    if (fromCache != null) return fromCache;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Redis read error for med {id}: {ex.Message}");
            }

            var medication = await _context.Medications.FindAsync(id);
            if (medication == null) return NotFound();

            try
            {
                var opts = new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10) };
                await _cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(medication), opts);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Redis write error for med {id}: {ex.Message}");
            }

            return medication;
        }

        // POST: api/medications
        [HttpPost]
        public async Task<ActionResult<Medication>> CreateMedication(Medication medication)
        {
            _context.Medications.Add(medication);
            await _context.SaveChangesAsync();
            await IncrementListVersionAsync();
            return CreatedAtAction(nameof(GetMedication), new { id = medication.Id }, medication);
        }

        // PUT: api/medications/{id}
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateMedication(int id, Medication medication)
        {
            if (id != medication.Id) return BadRequest();
            _context.Entry(medication).State = EntityState.Modified;
            try
            {
                await _context.SaveChangesAsync();
                await _cache.RemoveAsync($"med:{id}");
                await IncrementListVersionAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!_context.Medications.Any(m => m.Id == id)) return NotFound();
                throw;
            }
            return NoContent();
        }

        // DELETE: api/medications/{id}
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteMedication(int id)
        {
            var medication = await _context.Medications.FindAsync(id);
            if (medication == null) return NotFound();
            _context.Medications.Remove(medication);
            await _context.SaveChangesAsync();
            try
            {
                await _cache.RemoveAsync($"med:{id}");
                await IncrementListVersionAsync();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Redis eviction error for med {id}: {ex.Message}");
            }
            return NoContent();
        }

        private async Task<string> GetListVersionAsync()
        {
            const string versionKey = "meds-list-version";
            try
            {
                var v = await _cache.GetStringAsync(versionKey);
                if (string.IsNullOrEmpty(v))
                {
                    await _cache.SetStringAsync(versionKey, "1");
                    return "1";
                }
                return v;
            }
            catch
            {
                return "1";
            }
        }

        private async Task IncrementListVersionAsync()
        {
            const string versionKey = "meds-list-version";
            try
            {
                var current = await _cache.GetStringAsync(versionKey);
                int next = int.TryParse(current, out int val) ? val + 1 : 1;
                await _cache.SetStringAsync(versionKey, next.ToString());
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Redis version increment error: {ex.Message}");
            }
        }
    }
}
