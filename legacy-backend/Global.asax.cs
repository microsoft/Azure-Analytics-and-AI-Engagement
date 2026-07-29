using System;
using System.IO;
using System.Web;
using System.Web.Http;
using PharmacyLegacy.App_Start;
using PharmacyLegacy.Data;

namespace PharmacyLegacy
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            LoadDotEnv();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            DbSeeder.Seed();
        }

        private static void LoadDotEnv()
        {
            var path = Path.Combine(HttpRuntime.AppDomainAppPath, ".env");
            if (!File.Exists(path)) return;

            foreach (var line in File.ReadAllLines(path))
            {
                if (string.IsNullOrWhiteSpace(line) || line.StartsWith("#")) continue;
                var eq = line.IndexOf('=');
                if (eq < 1) continue;

                var key = line.Substring(0, eq).Trim();
                var value = line.Substring(eq + 1).Trim().Trim('"');
                Environment.SetEnvironmentVariable(key, value);
            }
        }
    }
}
