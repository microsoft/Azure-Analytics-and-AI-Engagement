using Azure.Messaging.ServiceBus;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Application.Services;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Options;
using System.Text.Json;

namespace HcpPortalApi.Worker;

public class EnrollmentEventWorker : BackgroundService
{
    private const string DefaultTenantCode = "caldova-hcp";
    private readonly ServiceBusClient _serviceBusClient;
    private readonly ILogger<EnrollmentEventWorker> _logger;
    private readonly IResponseCache? _responseCache;
    private readonly IConversationMemoryRepository? _memoryRepository;
    private readonly IEmbeddingService? _embeddingService;
    private readonly IClinicalGroundingRepository? _clinicalGroundingRepository;
    private readonly string _queueName;
    private ServiceBusProcessor? _processor;

    // Cache key prefix used for idempotency — prevents double-processing retried messages.
    private const string ProcessedCachePrefix = "enrollment:processed:";

    public EnrollmentEventWorker(
        ServiceBusClient serviceBusClient,
        ILogger<EnrollmentEventWorker> logger,
        IServiceProvider serviceProvider,
        IOptions<ServiceBusOptions> serviceBusOptions)
    {
        _serviceBusClient = serviceBusClient;
        _logger = logger;
        _queueName = string.IsNullOrWhiteSpace(serviceBusOptions.Value.QueueName)
            ? "enrollment-events"
            : serviceBusOptions.Value.QueueName;
        // Optional services — gracefully absent in local dev when Redis / Cosmos are not configured.
        _responseCache = serviceProvider.GetService<IResponseCache>();
        _memoryRepository = serviceProvider.GetService<IConversationMemoryRepository>();
        _embeddingService = serviceProvider.GetService<IEmbeddingService>();
        _clinicalGroundingRepository = serviceProvider.GetService<IClinicalGroundingRepository>();
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        try
        {
            _processor = _serviceBusClient.CreateProcessor(
                queueName: _queueName,
                new ServiceBusProcessorOptions
                {
                    AutoCompleteMessages = false,
                    MaxConcurrentCalls = 1
                });

            _processor.ProcessMessageAsync += MessageHandler;
            _processor.ProcessErrorAsync += ErrorHandler;

            _logger.LogInformation("Enrollment Worker started. Listening on queue: {QueueName}", _queueName);
            await _processor.StartProcessingAsync(stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(1000, stoppingToken);
            }

            await _processor.StopProcessingAsync();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Fatal error in EnrollmentEventWorker");
            throw;
        }
        finally
        {
            if (_processor is not null)
                await _processor.DisposeAsync();
        }
    }

    private async Task MessageHandler(ProcessMessageEventArgs args)
    {
        try
        {
            var body = args.Message.Body.ToString();
            var enrollmentEvent = JsonSerializer.Deserialize<EnrollmentCreatedEvent>(body,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (enrollmentEvent is not null)
            {
                // \u2500\u2500 Redis idempotency check \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
                var cacheKey = $"{ProcessedCachePrefix}{enrollmentEvent.EnrollmentId}";
                if (_responseCache is not null)
                {
                    try
                    {
                        var alreadyProcessed = await _responseCache.GetAsync<bool>(cacheKey, args.CancellationToken);
                        if (alreadyProcessed)
                        {
                            _logger.LogWarning(
                                "Enrollment {EnrollmentId} was already processed (Redis hit). Completing duplicate message.",
                                enrollmentEvent.EnrollmentId);
                            await args.CompleteMessageAsync(args.Message);
                            return;
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Redis idempotency check failed for enrollment {EnrollmentId}. Continuing without cache protection.", enrollmentEvent.EnrollmentId);
                    }
                }

                // \u2500\u2500 Core processing \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
                _logger.LogInformation(
                    "Enrollment Processed - EnrollmentId: {EnrollmentId} | NPI: {NPI} | Email: {Email} | CreatedUtc: {CreatedUtc}",
                    enrollmentEvent.EnrollmentId,
                    enrollmentEvent.Npi,
                    enrollmentEvent.Email,
                    enrollmentEvent.CreatedUtc);

                if (_clinicalGroundingRepository is not null)
                {
                    try
                    {
                        var groundingText = DemoClinicalGuidanceComposer.Build(
                            enrollmentEvent.Npi,
                            enrollmentEvent.FirstName,
                            enrollmentEvent.LastName,
                            enrollmentEvent.Email,
                            enrollmentEvent.Specialty,
                            enrollmentEvent.OrganizationName,
                            enrollmentEvent.CreatedUtc);
                        float[]? embedding = null;

                        if (_embeddingService is not null)
                        {
                            embedding = await _embeddingService.GenerateEmbeddingAsync(groundingText, args.CancellationToken);
                        }

                        var groundingDocument = new EnrollmentGroundingDocument(
                            enrollmentEvent.EnrollmentId,
                            DefaultTenantCode,
                            enrollmentEvent.Npi,
                            enrollmentEvent.FirstName,
                            enrollmentEvent.LastName,
                            enrollmentEvent.Email,
                            enrollmentEvent.Specialty,
                            enrollmentEvent.OrganizationName,
                            enrollmentEvent.CreatedUtc,
                            groundingText,
                            embedding,
                            _embeddingService is null ? null : "text-embedding-3-small");

                        await _clinicalGroundingRepository.SaveEnrollmentGroundingDocumentAsync(
                            groundingDocument,
                            args.CancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Grounding document persistence failed for enrollment {EnrollmentId}.", enrollmentEvent.EnrollmentId);
                    }
                }

                // TODO: Add downstream processing here
                // - Verify prescriber with EHR
                // - Send confirmation email
                // - Trigger document collection workflow

                // \u2500\u2500 Cosmos long-term memory \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
                if (_memoryRepository is not null)
                {
                    try
                    {
                        var tenantId = DefaultTenantCode;
                        var memoryKey = $"{tenantId}|{enrollmentEvent.Npi}";

                        var memory = new AgentMemoryEntry
                        {
                            MemoryKey = memoryKey,
                            TenantId = tenantId,
                            PrincipalId = enrollmentEvent.Npi,
                            MemoryType = "enrollment",
                            SourceConversationId = enrollmentEvent.EnrollmentId.ToString(),
                            Importance = 0.9,
                            Summary = $"Physician {enrollmentEvent.Npi} enrolled on {enrollmentEvent.CreatedUtc:yyyy-MM-dd}. " +
                                      $"Enrollment ID: {enrollmentEvent.EnrollmentId}.",
                            Tags = ["enrollment", "onboarding"],
                            UpdatedUtc = DateTimeOffset.UtcNow
                        };

                        await _memoryRepository.SaveAgentMemoryAsync(memory, args.CancellationToken);
                        _logger.LogDebug("Persisted enrollment memory for NPI {NPI} to Cosmos", enrollmentEvent.Npi);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Cosmos memory persistence failed for enrollment {EnrollmentId}.", enrollmentEvent.EnrollmentId);
                    }
                }

                // \u2500\u2500 Mark processed in Redis \u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500
                if (_responseCache is not null)
                {
                    try
                    {
                        await _responseCache.SetAsync(cacheKey, true, TimeSpan.FromHours(24), args.CancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Redis idempotency marker write failed for enrollment {EnrollmentId}.", enrollmentEvent.EnrollmentId);
                    }
                }
            }

            await args.CompleteMessageAsync(args.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing enrollment message. MessageId: {MessageId}", args.Message.MessageId);
            await args.AbandonMessageAsync(args.Message);
        }
    }

    private Task ErrorHandler(ProcessErrorEventArgs args)
    {
        _logger.LogError(
            args.Exception,
            "Service Bus error. Source: {ErrorSource} | Namespace: {Namespace} | EntityPath: {EntityPath}",
            args.ErrorSource,
            args.FullyQualifiedNamespace,
            args.EntityPath);
        return Task.CompletedTask;
    }

}

