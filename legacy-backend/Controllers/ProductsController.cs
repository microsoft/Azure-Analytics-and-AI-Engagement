using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using PharmacyLegacy.Data;
using PharmacyLegacy.Models;

namespace PharmacyLegacy.Controllers
{
    [RoutePrefix("api/medications")]
    public class MedicationsController : ApiController
    {
        // GET api/medications?category=&search=&page=1&pageSize=10
        [HttpGet, Route("")]
        public IHttpActionResult Get(string category = null, string search = null, int page = 1, int pageSize = 10)
        {
            using (var db = new PharmacyContext())
            {
                var q = db.Medications.AsQueryable();
                if (!string.IsNullOrEmpty(category)) q = q.Where(m => m.Category == category);
                if (!string.IsNullOrEmpty(search))   q = q.Where(m => m.Name.Contains(search) || m.GenericName.Contains(search) || m.Description.Contains(search));

                var total = q.Count();
                var items = q.OrderBy(m => m.Id).Skip((page - 1) * pageSize).Take(pageSize).ToList();
                return Ok(new { total, page, pageSize, data = items });
            }
        }

        // GET api/medications/5
        [HttpGet, Route("{id:int}")]
        public IHttpActionResult Get(int id)
        {
            using (var db = new PharmacyContext())
            {
                var m = db.Medications.Find(id);
                return m == null ? (IHttpActionResult)NotFound() : Ok(m);
            }
        }

        // POST api/medications
        [HttpPost, Route("")]
        public IHttpActionResult Post([FromBody] Medication medication)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            using (var db = new PharmacyContext())
            {
                db.Medications.Add(medication);
                db.SaveChanges();
                return Created($"api/medications/{medication.Id}", medication);
            }
        }

        // PUT api/medications/5
        [HttpPut, Route("{id:int}")]
        public IHttpActionResult Put(int id, [FromBody] Medication medication)
        {
            if (id != medication.Id) return BadRequest();
            if (!ModelState.IsValid) return BadRequest(ModelState);
            using (var db = new PharmacyContext())
            {
                db.Entry(medication).State = EntityState.Modified;
                db.SaveChanges();
                return StatusCode(HttpStatusCode.NoContent);
            }
        }

        // DELETE api/medications/5
        [HttpDelete, Route("{id:int}")]
        public IHttpActionResult Delete(int id)
        {
            using (var db = new PharmacyContext())
            {
                var m = db.Medications.Find(id);
                if (m == null) return NotFound();
                db.Medications.Remove(m);
                db.SaveChanges();
                return StatusCode(HttpStatusCode.NoContent);
            }
        }
    }
}
