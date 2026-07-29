using Azure.Extensions.AspNetCore.Configuration.Secrets;
using Azure.Identity;
using HcpPortal;
using HcpPortal.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.OpenApi;
using System.Reflection;

var builder = WebApplication.CreateBuilder(args);

// Bootstrap cloud endpoints from default host configuration.
var kvUri = builder.Configuration["AZURE_KEYVAULT_URI"];
var appConfigEndpoint = builder.Configuration["AZURE_APPCONFIG_ENDPOINT"];
var isAzureAppConfigurationEnabled = !string.IsNullOrWhiteSpace(appConfigEndpoint);

// Rebuild configuration order to match PharmaBackend precedence.
builder.Configuration.Sources.Clear();

builder.Configuration
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile($"appsettings.{builder.Environment.EnvironmentName}.json", optional: true, reloadOnChange: true);

if (!string.IsNullOrWhiteSpace(kvUri))
{
    HcpPortalConfiguration.TryAddAzureKeyVault(
        kvUri,
        uri =>
        {
            builder.Configuration.AddAzureKeyVault(uri, new DefaultAzureCredential());
            return true;
        });
}

if (isAzureAppConfigurationEnabled)
{
    var appConfigUri = appConfigEndpoint!;
    var appConfigCredential = new DefaultAzureCredential();
    builder.Configuration.AddAzureAppConfiguration(options =>
    {
        options
            .Connect(new Uri(appConfigUri), appConfigCredential)
            .ConfigureKeyVault(kv => kv.SetCredential(appConfigCredential))
            .ConfigureRefresh(refresh => refresh.Register("Sentinel", refreshAll: true));
    });

    builder.Services.AddAzureAppConfiguration();
}

builder.Configuration.AddEnvironmentVariables();

if (builder.Environment.IsDevelopment())
{
    builder.Configuration.AddUserSecrets<Program>();
}

var entryAssemblyName = Assembly.GetEntryAssembly()?.GetName().Name;
var isOpenApiGeneration = string.Equals(entryAssemblyName, "dotnet-getdocument", StringComparison.OrdinalIgnoreCase)
    || string.Equals(entryAssemblyName, "GetDocument.Insider", StringComparison.OrdinalIgnoreCase);

var authAuthority = builder.Configuration["Auth:Authority"];
var authAudience = builder.Configuration["Auth:Audience"];
var authEnabled = !string.IsNullOrWhiteSpace(authAuthority) && !string.IsNullOrWhiteSpace(authAudience);

if (!authEnabled && !builder.Environment.IsDevelopment() && !isOpenApiGeneration)
{
    throw new InvalidOperationException(
        "Authentication is not configured. Set Auth:Authority and Auth:Audience via environment variables, App Configuration, or Key Vault.");
}

var downstreamCredential = builder.Configuration[HcpPortalConfiguration.Patient360CredentialKey];

if (string.IsNullOrWhiteSpace(downstreamCredential) && !isOpenApiGeneration)
{
    throw new InvalidOperationException(
        "Patient360 downstream credential is not configured. Supply it via Azure Key Vault, " +
        "Azure App Configuration, environment variables, or user-secrets.");
}

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "HcpPortal API",
        Version = "v1"
    });
});

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
        else if (!isOpenApiGeneration)
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

builder.Services.AddScoped<IPrescriberService, PrescriberService>();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "HcpPortal API v1");
    });
}

app.UseHttpsRedirection();

if (isAzureAppConfigurationEnabled)
{
    app.UseAzureAppConfiguration();
}

app.UseCors("RestrictedCors");

if (authEnabled)
{
    app.UseAuthentication();
}

app.UseAuthorization();
app.MapControllers();

app.Run();

public partial class Program;
