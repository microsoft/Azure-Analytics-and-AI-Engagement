using DataAiMegamap.Web.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;

namespace DataAiMegamap.Web.Controllers
{
  [Route("api/")]
  public class ConfigController : Controller
  {
    private AppSettings AppSettings { get; set; }

    public ConfigController(IOptions<AppSettings> settings)
    {
      AppSettings = settings.Value;
    }

   

    [HttpGet]
    [Route("appinsightskey")]
    [AllowAnonymous]
    public ActionResult<string> GetAppSettings()
    {
      return Ok(AppSettings.AppinsightsKey);
    }
  }

}
