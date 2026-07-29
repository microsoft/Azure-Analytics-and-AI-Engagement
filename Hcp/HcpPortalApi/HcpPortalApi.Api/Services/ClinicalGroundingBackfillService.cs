using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Application.Services;
using HcpPortalApi.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using System.Security.Cryptography;
using System.Text;

namespace HcpPortalApi.Api.Services;

public sealed class ClinicalGroundingBackfillService : BackgroundService
{
    private const string TenantCode = "caldova-hcp";
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ClinicalGroundingBackfillService> _logger;

    public ClinicalGroundingBackfillService(
        IServiceScopeFactory scopeFactory,
        ILogger<ClinicalGroundingBackfillService> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await using var scope = _scopeFactory.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<HcpPortalDbContext>();
        var embeddingService = scope.ServiceProvider.GetRequiredService<IEmbeddingService>();
        var groundingRepository = scope.ServiceProvider.GetRequiredService<IClinicalGroundingRepository>();

        await SeedGlobalClinicalReferencesAsync(embeddingService, groundingRepository, stoppingToken);

        var enrollments = await dbContext.PhysicianEnrollments
            .AsNoTracking()
            .OrderByDescending(enrollment => enrollment.CreatedUtc)
            .Take(25)
            .ToListAsync(stoppingToken);

        foreach (var enrollment in enrollments)
        {
            try
            {
                var groundingText = DemoClinicalGuidanceComposer.Build(
                    enrollment.Npi,
                    enrollment.FirstName,
                    enrollment.LastName,
                    enrollment.Email,
                    enrollment.Specialty,
                    enrollment.OrganizationName,
                    enrollment.CreatedUtc);

                var embedding = await embeddingService.GenerateEmbeddingAsync(groundingText, stoppingToken);

                var groundingDocument = new EnrollmentGroundingDocument(
                    enrollment.Id,
                    TenantCode,
                    enrollment.Npi,
                    enrollment.FirstName,
                    enrollment.LastName,
                    enrollment.Email,
                    enrollment.Specialty,
                    enrollment.OrganizationName,
                    enrollment.CreatedUtc,
                    groundingText,
                    embedding,
                    "text-embedding-3-small");

                await groundingRepository.SaveEnrollmentGroundingDocumentAsync(groundingDocument, stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Grounding backfill failed for enrollment {EnrollmentId}.", enrollment.Id);
            }
        }

        _logger.LogInformation("Clinical grounding backfill processed {Count} enrollment records.", enrollments.Count);
    }

    private async Task SeedGlobalClinicalReferencesAsync(
        IEmbeddingService embeddingService,
        IClinicalGroundingRepository groundingRepository,
        CancellationToken cancellationToken)
    {
        var references = DemoClinicalReferenceCatalog.Build();

        foreach (var reference in references)
        {
            try
            {
                var embedding = await embeddingService.GenerateEmbeddingAsync(reference.ContentText, cancellationToken);

                var deterministicGuid = DeterministicGuid(reference.Key);
                var referenceDocument = new EnrollmentGroundingDocument(
                    deterministicGuid,
                    TenantCode,
                    string.Empty,
                    "Clinical",
                    "Reference",
                    "clinical-reference@caldova.demo",
                    "Clinical Guidance",
                    reference.Title,
                    DateTimeOffset.UtcNow,
                    reference.ContentText,
                    embedding,
                    "text-embedding-3-small");

                await groundingRepository.SaveEnrollmentGroundingDocumentAsync(referenceDocument, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed seeding global clinical reference {ReferenceKey}", reference.Key);
            }
        }
    }

    private static Guid DeterministicGuid(string key)
    {
        using var sha1 = SHA1.Create();
        var bytes = sha1.ComputeHash(Encoding.UTF8.GetBytes($"clinical-reference:{key}"));
        Span<byte> guidBytes = stackalloc byte[16];
        bytes.AsSpan(0, 16).CopyTo(guidBytes);
        return new Guid(guidBytes);
    }
}