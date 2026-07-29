using Azure.Core;
using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Azure.Identity;
using HealthChecks.UI.Client;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using PharmacyBackend.Data;
using StackExchange.Redis;

var builder = WebApplication.CreateBuilder(args);

// ── Bootstrap: read Azure service endpoints before rebuilding configuration ─
// builder.Configuration already contains appsettings.json, appsettings.{env}.json,
// env vars, and user-secrets at this point — sufficient to resolve the endpoint
// values that control which cloud providers are activated.
var kvUri             = builder.Configuration["AZURE_KEYVAULT_URI"];
var appConfigEndpoint = builder.Configuration["AZURE_APPCONFIG_ENDPOINT"];

// ── Rebuild configuration in the required precedence order ──────────────────
// Lowest → highest:
//   appsettings.json → appsettings.{env}.json
//   → Key Vault → App Configuration → env vars → user-secrets
builder.Configuration.Sources.Clear();

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json",
                 optional: true, reloadOnChange: true);

// Key Vault: provides secrets (connection strings, API keys).
//   Local dev → DefaultAzureCredential resolves via Azure CLI / VS Code creds.
//   AKS       → DefaultAzureCredential resolves via Workload Identity (OIDC / UAMI).
// Secrets use double-dash separators ("ConnectionStrings--DefaultConnection") which
// the configuration system maps automatically to "ConnectionStrings:DefaultConnection".
if (!string.IsNullOrWhiteSpace(kvUri))
{
    builder.Configuration.AddAzureKeyVault(
        new Uri(kvUri),
        new DefaultAzureCredential());
}

// Azure App Configuration: central store for non-secret settings and feature flags.
//   - Non-secret keys (Logging:LogLevel:*, AllowedHosts, future feature flags) are
//     stored here; appsettings.json keeps the same keys as local-dev defaults.
//   - Key Vault references in App Configuration are resolved through the same
//     managed-identity credential, so no secret values are stored in App Config.
//   - Dynamic refresh: updating the "Sentinel" key in the App Configuration store
//     causes all settings to be reloaded at the next incoming request.
if (!string.IsNullOrWhiteSpace(appConfigEndpoint))
{
    var appConfigCredential = new DefaultAzureCredential();
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options
            .Connect(new Uri(appConfigEndpoint), appConfigCredential)
            // Resolve Key Vault references stored in App Configuration through
            // the same managed-identity / developer credential.
            .ConfigureKeyVault(kv => kv.SetCredential(appConfigCredential))
            // Refresh all settings whenever the "Sentinel" key value changes.
            .ConfigureRefresh(refresh =>
                refresh.Register("Sentinel", refreshAll: true));
    });
}

// Environment variables override cloud config — pod/node-level tuning in AKS.
builder.Configuration.AddEnvironmentVariables();

// User secrets are the highest-priority local-dev override; absent in production.
if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<Program>();
}

var authAuthority = builder.Configuration["Auth:Authority"];
var authAudience = builder.Configuration["Auth:Audience"];
var authEnabled = !string.IsNullOrWhiteSpace(authAuthority) && !string.IsNullOrWhiteSpace(authAudience);

if (!authEnabled && !builder.Environment.IsDevelopment())
{
    throw new InvalidOperationException(
        "Authentication is not configured. Set Auth:Authority and Auth:Audience via environment variables, App Configuration, or Key Vault.");
}

// Fail fast: Redis host name and principal ID must be supplied at runtime.
var redisHostName = builder.Configuration["Redis:HostName"];

if (string.IsNullOrWhiteSpace(redisHostName))
    throw new InvalidOperationException(
        "Redis:HostName is not configured. " +
        "Supply it via Azure App Configuration, environment variables, or user-secrets.");

var redisPrincipalId = builder.Configuration["Redis:PrincipalId"];

if (string.IsNullOrWhiteSpace(redisPrincipalId))
    throw new InvalidOperationException(
        "Redis:PrincipalId is not configured. " +
        "Supply the Object (Principal) ID of the Entra ID managed identity or user authorised on the Azure Cache for Redis instance. " +
        "Supply it via Azure App Configuration, environment variables, or user-secrets.");

// ── SQL Server — Passwordless / Managed Identity ─────────────────────────────
// The connection string is sourced from Azure App Configuration (or
// user-secrets / environment variables for local development).
// Use "Authentication=Active Directory Default" in the connection string to
// enable passwordless access via DefaultAzureCredential (Workload Identity on
// AKS, Azure CLI / VS Code credentials on a developer workstation).
var sqlConnectionString = builder.Configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrWhiteSpace(sqlConnectionString))
    throw new InvalidOperationException(
        "ConnectionStrings:DefaultConnection is not configured. " +
        "Supply it via Azure App Configuration, environment variables, or user-secrets.");

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(sqlConnectionString));

// ── Redis — Passwordless / Managed Identity ──────────────────────────────────
// ConfigureForAzureWithTokenCredentialAsync wires up a ReconnectRetryPolicy and
// an auth callback so StackExchange.Redis obtains short-lived Azure AD access
// tokens via DefaultAzureCredential instead of using an access key or password.
var redisCredential = new DefaultAzureCredential();
var redisOptions = ConfigurationOptions.Parse($"{redisHostName}:6380");
await redisOptions.ConfigureForAzureWithTokenCredentialAsync(redisPrincipalId, redisCredential);

builder.Services.AddStackExchangeRedisCache(options =>
{
    options.ConfigurationOptions = redisOptions;
    options.InstanceName = "Pharmacy_";
});

// Shared IConnectionMultiplexer resolved lazily on first health-check probe —
// avoids blocking startup if Redis is transiently unavailable.
builder.Services.AddSingleton<IConnectionMultiplexer>(
    _ => ConnectionMultiplexer.Connect(redisOptions));

builder.Services.AddHealthChecks()
    .AddCheck("liveness", () => HealthCheckResult.Healthy(), tags: new[] { "live" })
    .AddSqlServer(sqlConnectionString!, tags: new[] { "ready" })
    .AddRedis(sp => sp.GetRequiredService<IConnectionMultiplexer>(), tags: new[] { "ready" });

builder.Services.AddSwaggerGen();

builder.Services.AddCors(options =>
{
    var allowedOrigins = builder.Configuration
        .GetSection("Cors:AllowedOrigins")
        .Get<string[]>()
        ?.Where(origin => !string.IsNullOrWhiteSpace(origin))
        .Select(origin => origin.Trim())
        .Distinct(StringComparer.OrdinalIgnoreCase)
        .ToArray() ?? Array.Empty<string>();

    if (allowedOrigins.Length == 0)
    {
        if (builder.Environment.IsDevelopment())
        {
            allowedOrigins = new[]
            {
                "http://localhost:5173",
                "https://localhost:5173",
                "http://localhost:3000",
                "https://localhost:3000"
            };
        }
        else
        {
            throw new InvalidOperationException(
                "Cors:AllowedOrigins is not configured. Configure at least one allowed origin in production.");
        }
    }

    options.AddPolicy("RestrictedCors", policy =>
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod());
});

if (authEnabled)
{
    builder.Services
        .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            options.Authority = authAuthority;
            options.Audience = authAudience;
            options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
        });

    builder.Services.AddAuthorization(options =>
    {
        options.FallbackPolicy = new AuthorizationPolicyBuilder()
            .RequireAuthenticatedUser()
            .Build();
    });
}
else
{
    builder.Services.AddAuthorization();
}

builder.Services.AddControllers();

var app = builder.Build();

using (var scope = app.Services.CreateScope())
{
    var db     = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    var config = scope.ServiceProvider.GetRequiredService<IConfiguration>();
    db.Database.Migrate();
    DbSeeder.Seed(db, config);
}

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("RestrictedCors");

// Azure App Configuration refresh middleware: polls the "Sentinel" key on each
// request (after the refresh cache window expires) and reloads all settings when
// the key has changed — enabling zero-downtime config updates without pod restarts.
// No-op when AZURE_APPCONFIG_ENDPOINT is unset (no refresher registered).
app.UseAzureAppConfiguration();

if (authEnabled)
{
    app.UseAuthentication();
}

app.UseAuthorization();
app.MapControllers();

app.MapHealthChecks("/health/live", new HealthCheckOptions
{
    Predicate = r => r.Tags.Contains("live"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
}).AllowAnonymous();

app.MapHealthChecks("/health/ready", new HealthCheckOptions
{
    Predicate = r => r.Tags.Contains("ready"),
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
}).AllowAnonymous();

app.Run();
