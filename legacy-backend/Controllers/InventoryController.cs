using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using PharmacyLegacy.Data;
using PharmacyLegacy.Models;

namespace PharmacyLegacy.Controllers
{
    [RoutePrefix("api/inventory")]
    public class InventoryController : ApiController
    {
        // GET api/inventory?lowStock=true&page=1&pageSize=10
        [HttpGet, Route("")]
        public IHttpActionResult Get(bool? lowStock = null, int page = 1, int pageSize = 10)
        {
            using (var db = new PharmacyContext())
            {
                var q = db.Inventories.Include(i => i.Medication).AsQueryable();
                if (lowStock == true) q = q.Where(i => i.QuantityOnHand <= i.ReorderLevel);

                var total = q.Count();
                var items = q.OrderBy(i => i.StorageLocation).Skip((page - 1) * pageSize).Take(pageSize).ToList();
                return Ok(new { total, page, pageSize, data = items });
            }
        }

        // GET api/inventory/5
        [HttpGet, Route("{id:int}")]
        public IHttpActionResult Get(int id)
        {
            using (var db = new PharmacyContext())
            {
                var i = db.Inventories.Include(x => x.Medication).FirstOrDefault(x => x.Id == id);
                return i == null ? (IHttpActionResult)NotFound() : Ok(i);
            }
        }

        // GET api/inventory/medication/5
        [HttpGet, Route("medication/{medicationId:int}")]
        public IHttpActionResult GetByMedication(int medicationId)
        {
            using (var db = new PharmacyContext())
            {
                var i = db.Inventories.Include(x => x.Medication).FirstOrDefault(x => x.MedicationId == medicationId);
                return i == null ? (IHttpActionResult)NotFound() : Ok(i);
            }
        }

        // PUT api/inventory/5
        [HttpPut, Route("{id:int}")]
        public IHttpActionResult Put(int id, [FromBody] Inventory inventory)
        {
            if (id != inventory.Id) return BadRequest();
            inventory.LastUpdated = DateTime.UtcNow;
            using (var db = new PharmacyContext())
            {
                db.Entry(inventory).State = EntityState.Modified;
                db.SaveChanges();
                return StatusCode(HttpStatusCode.NoContent);
            }
        }

        // PATCH api/inventory/5/adjust  body: { "delta": -5 }
        [HttpPatch, Route("{id:int}/adjust")]
        public IHttpActionResult Adjust(int id, [FromBody] int delta)
        {
            using (var db = new PharmacyContext())
            {
                var i = db.Inventories.Find(id);
                if (i == null) return NotFound();
                i.QuantityOnHand = Math.Max(0, i.QuantityOnHand + delta);
                i.LastUpdated    = DateTime.UtcNow;
                db.SaveChanges();
                return Ok(i);
            }
        }
    }
}
