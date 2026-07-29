using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web.Http;
using PharmacyLegacy.Data;
using PharmacyLegacy.Models;

namespace PharmacyLegacy.Controllers
{
    [RoutePrefix("api/patients")]
    public class PatientsController : ApiController
    {
        // GET api/patients?search=&page=1&pageSize=10
        [HttpGet, Route("")]
        public IHttpActionResult Get(string search = null, int page = 1, int pageSize = 10)
        {
            using (var db = new PharmacyContext())
            {
                var q = db.Patients.AsQueryable();
                if (!string.IsNullOrEmpty(search))
                    q = q.Where(p => p.FirstName.Contains(search) || p.LastName.Contains(search) || p.Email.Contains(search));

                var total    = q.Count();
                var patients = q.OrderBy(p => p.LastName).Skip((page - 1) * pageSize).Take(pageSize).ToList();
                return Ok(new { total, page, pageSize, data = patients });
            }
        }

        // GET api/patients/5
        [HttpGet, Route("{id:int}")]
        public IHttpActionResult Get(int id)
        {
            using (var db = new PharmacyContext())
            {
                var p = db.Patients.Include(x => x.Orders).FirstOrDefault(x => x.Id == id);
                return p == null ? (IHttpActionResult)NotFound() : Ok(p);
            }
        }

        // POST api/patients
        [HttpPost, Route("")]
        public IHttpActionResult Post([FromBody] Patient patient)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);
            using (var db = new PharmacyContext())
            {
                db.Patients.Add(patient);
                db.SaveChanges();
                return Created($"api/patients/{patient.Id}", patient);
            }
        }

        // PUT api/patients/5
        [HttpPut, Route("{id:int}")]
        public IHttpActionResult Put(int id, [FromBody] Patient patient)
        {
            if (id != patient.Id) return BadRequest();
            if (!ModelState.IsValid) return BadRequest(ModelState);
            using (var db = new PharmacyContext())
            {
                db.Entry(patient).State = EntityState.Modified;
                db.SaveChanges();
                return StatusCode(HttpStatusCode.NoContent);
            }
        }

        // DELETE api/patients/5
        [HttpDelete, Route("{id:int}")]
        public IHttpActionResult Delete(int id)
        {
            using (var db = new PharmacyContext())
            {
                var p = db.Patients.Find(id);
                if (p == null) return NotFound();
                db.Patients.Remove(p);
                db.SaveChanges();
                return StatusCode(HttpStatusCode.NoContent);
            }
        }
    }
}
