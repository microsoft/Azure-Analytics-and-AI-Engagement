using Azure;
using Azure.AI.OpenAI;
using Azure.Core;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Infrastructure.AI;
using HcpPortalApi.Infrastructure.Messaging;
using HcpPortalApi.Infrastructure.Options;
using HcpPortalApi.Infrastructure.Persistence;
using HcpPortalApi.Infrastructure.Repositories;
using HcpPortalApi.Infrastructure.SandboxSessions;
using HcpPortalApi.Infrastructure.Serialization;
using HcpPortalApi.Infrastructure.Caching;
using Microsoft.Azure.Cosmos;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;

namespace HcpPortalApi.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var sqlConnectionString = configuration.GetConnectionString("HcpSql");

        if (string.IsNullOrWhiteSpace(sqlConnectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:HcpSql is not configured. Supply it via environment variables, secret store, or Kubernetes secret.");
        }

        services.AddDbContext<HcpPortalDbContext>(options =>
            options.UseSqlServer(sqlConnectionString));

        services.Configure<ServiceBusOptions>(configuration.GetSection(ServiceBusOptions.SectionName));

        services.AddSingleton<ServiceBusClient>(sp =>
        {
            var options = sp.GetRequiredService<IOptions<ServiceBusOptions>>().Value;

            if (!string.IsNullOrWhiteSpace(options.FullyQualifiedNamespace))
            {
                return new ServiceBusClient(options.FullyQualifiedNamespace, new DefaultAzureCredential());
            }

            throw new InvalidOperationException(
                "ServiceBus is not configured. Set ServiceBus:FullyQualifiedNamespace for managed identity.");
        });

        services.AddScoped<IPhysicianEnrollmentRepository, PhysicianEnrollmentRepository>();
        services.AddSingleton<IEnrollmentEventPublisher, ServiceBusEnrollmentEventPublisher>();

        services.Configure<HorizonDbOptions>(configuration.GetSection(HorizonDbOptions.SectionName));
        var horizonDbConnectionString = configuration[$"{HorizonDbOptions.SectionName}:ConnectionString"];
        if (string.IsNullOrWhiteSpace(horizonDbConnectionString))
        {
            throw new InvalidOperationException(
                "HorizonDb:ConnectionString is not configured. Supply it via environment variables, secret store, or Kubernetes secret.");
        }
        services.AddScoped<IClinicalGroundingRepository, PostgresClinicalGroundingRepository>();

        services.Configure<RedisOptions>(configuration.GetSection(RedisOptions.SectionName));

        var redisConnectionString = configuration.GetConnectionString("Redis")
            ?? configuration[$"{RedisOptions.SectionName}:ConnectionString"];
        if (string.IsNullOrWhiteSpace(redisConnectionString))
        {
            throw new InvalidOperationException(
                "ConnectionStrings:Redis or Redis:ConnectionString is not configured. Supply it via environment variables, secret store, or Kubernetes secret.");
        }

        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = redisConnectionString;
        });
        services.AddScoped<IResponseCache, RedisResponseCache>();

        // ── Foundry embeddings + grounded answer synthesis (required) ──────────
        services.Configure<FoundryOptions>(configuration.GetSection(FoundryOptions.SectionName));
        var foundryEndpoint = configuration[$"{FoundryOptions.SectionName}:Endpoint"];
        if (string.IsNullOrWhiteSpace(foundryEndpoint))
        {
            throw new InvalidOperationException(
                "Foundry:Endpoint is not configured. Supply it via environment variables, secret store, or Kubernetes secret.");
        }

        var embeddingDeployment = configuration[$"{FoundryOptions.SectionName}:EmbeddingModelDeployment"];
        if (string.IsNullOrWhiteSpace(embeddingDeployment))
        {
            throw new InvalidOperationException(
                "Foundry:EmbeddingModelDeployment is not configured. Supply it via configuration.");
        }
        var chatDeployment = configuration[$"{FoundryOptions.SectionName}:ChatModelDeployment"];
        if (string.IsNullOrWhiteSpace(chatDeployment))
        {
            throw new InvalidOperationException(
                "Foundry:ChatModelDeployment is not configured. Supply it via configuration.");
        }
        services.AddSingleton<IEmbeddingService, FoundryEmbeddingService>();
        services.AddSingleton<IGroundedAnswerService, FoundryGroundedAnswerService>();

        // ── Cosmos DB long-term conversation memory (required) ──────────────────
        var cosmosEndpoint = configuration[$"{CosmosOptions.SectionName}:AccountEndpoint"];
        if (string.IsNullOrWhiteSpace(cosmosEndpoint))
        {
            throw new InvalidOperationException(
                "Cosmos:AccountEndpoint is not configured. Supply it via environment variables, secret store, or Kubernetes secret.");
        }
        services.Configure<CosmosOptions>(configuration.GetSection(CosmosOptions.SectionName));

        services.AddSingleton<CosmosClient>(sp =>
        {
            var opts = sp.GetRequiredService<IOptions<CosmosOptions>>().Value;
            var clientOptions = new CosmosClientOptions
            {
                Serializer = new CamelCaseCosmosSerializer()
            };

            return new CosmosClient(opts.AccountEndpoint, new DefaultAzureCredential(), clientOptions);
        });

        services.AddScoped<IConversationMemoryRepository, CosmosConversationMemoryRepository>();

        // ── ACA Sandbox Group (prescriber session mapping) ─────────────────────
        services.Configure<SandboxGroupOptions>(configuration.GetSection(SandboxGroupOptions.SectionName));
        services.Configure<SessionPoolOptions>(configuration.GetSection(SessionPoolOptions.SectionName));
        services.AddSingleton<TokenCredential, DefaultAzureCredential>();
        services.AddHttpClient<ISandboxSessionService, AcaSandboxSessionService>();

        services.Configure<SandboxRuntimeOptions>(configuration.GetSection(SandboxRuntimeOptions.SectionName));
        var sandboxRuntimeBaseUrlTemplate = configuration[$"{SandboxRuntimeOptions.SectionName}:BaseUrlTemplate"];
        if (string.IsNullOrWhiteSpace(sandboxRuntimeBaseUrlTemplate))
        {
            throw new InvalidOperationException(
                "SandboxRuntime:BaseUrlTemplate is not configured. Supply it via environment variables, secret store, or Kubernetes secret.");
        }
        services.AddHttpClient<ISandboxAssistantExecutor, AcaSandboxAssistantExecutor>();

        return services;
    }
}