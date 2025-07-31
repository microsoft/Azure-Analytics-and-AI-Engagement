using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using Microsoft.Identity.Client;
using Newtonsoft.Json;

namespace server.Controllers
{
    [Route("api/[controller]")]
    public class TokenController : Controller
    {


        private readonly IOptions<ConfigurationModel> appSettings;

        public TokenController(IOptions<ConfigurationModel> appSettings)
        {
            this.appSettings = appSettings;
            baseUrl = appSettings.Value.BaseUrl;
        }


        private static string baseUrl;
        private static AuthenticationResult authentication;
        private static Dictionary<string, EmbededToken> embedTokenCache = new Dictionary<string, EmbededToken>();
        //private static string baseUrl = "https://api.powerbi.com/v1.0/myorg/groups/b5cc6583-8061-4b6c-bb54-f341533309b9";

        private static HttpRequestMessage FormRequest(string type, string id, bool editMode)
        {
            string tokenEndpointUri = "";

            if (type == "report")
            {
                tokenEndpointUri = $"{baseUrl}/reports/{id}/GenerateToken";
            }
            else if (type == "dashboard")
            {
                tokenEndpointUri = $"{baseUrl}/dashboards/{id}/GenerateToken";
            }
            else if (type == "qna")
            {
                tokenEndpointUri = $"{baseUrl}/datasets/{id}/GenerateToken";
            }

            var content = new FormUrlEncodedContent(new[] {
                new KeyValuePair<string, string>("accessLevel", editMode ? "Edit" : "View")
            });

            var request = new HttpRequestMessage()
            {
                RequestUri = new Uri(tokenEndpointUri),
                Method = HttpMethod.Post,
                Content = content
            };
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", authentication.AccessToken);
            return request;
        }

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        [Route("Embed/{type}/{id}")]
        public async Task<IActionResult> GetEmbedToken(string type, string id, [FromQuery] bool editMode = false)
        {
            var accesstoken = "";
            if (string.IsNullOrEmpty(type) || string.IsNullOrEmpty(id)) return BadRequest();

            string tokenKey = $"{type}-{id}-{editMode}";
            bool tokenExists = embedTokenCache.ContainsKey(tokenKey);
            if (tokenExists && !string.IsNullOrEmpty(embedTokenCache[tokenKey].token) && !HasEmbedTokenExpired(embedTokenCache[tokenKey]))
            {
                return Ok(embedTokenCache[tokenKey].token);
            }

            if (authentication == null || authentication.AccessToken == null || HasTokenExpired())
            {
                accesstoken= GetAccessToken();
            }

            using (var client = new HttpClient())
            {
                var request = FormRequest(type, id, editMode);
                var requestContent = await request.Content.ReadAsStringAsync();

                HttpResponseMessage res = await client.SendAsync(request);
                var resContent = await res.Content.ReadAsStringAsync();
                EmbededToken tokenRes = JsonConvert.DeserializeObject<EmbededToken>(resContent);
                if (tokenRes != null && !string.IsNullOrEmpty(tokenRes.token))
                {
                    embedTokenCache[tokenKey] = tokenRes;
                }
                else
                {
                    throw new Exception("invalid access token response", new Exception(
                        $"request: {JsonConvert.SerializeObject(request)},\n requestContent: {requestContent},\n res: {JsonConvert.SerializeObject(res)},\n resContent: {resContent}, \n tokenRes: {JsonConvert.SerializeObject(tokenRes)}"
                    ));
                }

                return Ok(tokenRes.token);
            }
        }

        public bool HasEmbedTokenExpired(EmbededToken token)
        {
            long timeNow = DateTimeOffset.Now.ToUnixTimeSeconds();
            long expireDate = DateTimeOffset.Parse(token.expiration).ToUnixTimeSeconds();
            return timeNow > expireDate;
        }

        public bool HasTokenExpired()
        {
            long timeNow = DateTimeOffset.Now.ToUnixTimeSeconds();
            long expireDate = authentication.ExpiresOn.ToUnixTimeSeconds();
            return timeNow > expireDate;
        }

        [Route("Access")]
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public string GetAccessToken()
        {

            authentication = AadService.GetAccessToken(appSettings);
            return authentication.AccessToken;

        }
    }

    public class AzureAdTokenResponse
    {
        public string token_type { get; set; }
        public string scope { get; set; }
        public string expires_in { get; set; }
        public string ext_expires_in { get; set; }
        public string expires_on { get; set; }
        public string not_before { get; set; }
        public string resource { get; set; }
        public string access_token { get; set; }
        public string refresh_token { get; set; }
    }

    public class EmbededToken
    {
        public string token { get; set; }
        public string tokenId { get; set; }
        public string expiration { get; set; }
    }
}