using System;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using PharmacyLegacy.Data;
using PharmacyLegacy.Models;

namespace PharmacyLegacy.Controllers
{
    [RoutePrefix("api/orders")]
    public class OrdersController : ApiController
    {
        // GET api/orders?status=&patientId=&page=1&pageSize=10
        [HttpGet, Route("")]
        public IHttpActionResult Get(string status = null, int? patientId = null, int page = 1, int pageSize = 10)
        {
            using (var db = new PharmacyContext())
            {
                var q = db.Orders.Include(o => o.Patient).Include(o => o.Items.Select(i => i.Medication)).AsQueryable();
                if (!string.IsNullOrEmpty(status)) q = q.Where(o => o.Status == status);
                if (patientId.HasValue)             q = q.Where(o => o.PatientId == patientId.Value);

                var total  = q.Count();
                var orders = q.OrderByDescending(o => o.OrderDate).Skip((page - 1) * pageSize).Take(pageSize).ToList();
                return Ok(new { total, page, pageSize, data = orders });
            }
        }

        // GET api/orders/5
        [HttpGet, Route("{id:int}")]
        public IHttpActionResult Get(int id)
        {
            using (var db = new PharmacyContext())
            {
                var o = db.Orders.Include(x => x.Patient).Include(x => x.Items.Select(i => i.Medication)).FirstOrDefault(x => x.Id == id);
                return o == null ? (IHttpActionResult)NotFound() : Ok(o);
            }
        }

        // POST api/orders
        [HttpPost, Route("")]
        public IHttpActionResult Post([FromBody] Order order)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            order.OrderDate   = DateTime.UtcNow;
            order.TotalAmount = 0;
            foreach (var item in order.Items) order.TotalAmount += item.Quantity * item.UnitPrice;
            using (var db = new PharmacyContext())
            {
                db.Orders.Add(order);
                db.SaveChanges();
                return Created($"api/orders/{order.Id}", order);
            }
        }

        // PUT api/orders/5/status
        [HttpPut, Route("{id:int}/status")]
        public IHttpActionResult UpdateStatus(int id, [FromBody] string status)
        {
            using (var db = new PharmacyContext())
            {
                var o = db.Orders.Find(id);
                if (o == null) return NotFound();
                o.Status = status;
                db.SaveChanges();
                return StatusCode(HttpStatusCode.NoContent);
            }
        }

        // DELETE api/orders/5
        [HttpDelete, Route("{id:int}")]
        public IHttpActionResult Delete(int id)
        {
            using (var db = new PharmacyContext())
            {
                var o = db.Orders.Find(id);
                if (o == null) return NotFound();
                db.Orders.Remove(o);
                db.SaveChanges();
                return StatusCode(HttpStatusCode.NoContent);
            }
        }
    }
}
