using System.Globalization;
using System.Text.Json;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;

namespace HcpPortalApi.Infrastructure.Repositories;

public sealed class PostgresClinicalGroundingRepository : IClinicalGroundingRepository
{
    private const string TenantContextSetting = "app.tenant_id";
    private readonly HorizonDbOptions _options;
    private readonly ILogger<PostgresClinicalGroundingRepository> _logger;

    public PostgresClinicalGroundingRepository(
        IOptions<HorizonDbOptions> options,
        ILogger<PostgresClinicalGroundingRepository> logger)
    {
        _options = options.Value;
        _logger = logger;
    }

    public async Task SaveEnrollmentGroundingDocumentAsync(
        EnrollmentGroundingDocument document,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.ConnectionString))
        {
            throw new InvalidOperationException(
                "HorizonDb:ConnectionString is not configured. Supply it via environment variables or a secure secret store.");
        }

        await using var connection = new NpgsqlConnection(_options.ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        var tenantId = await UpsertTenantAsync(connection, transaction, document, cancellationToken);
        await SetTenantContextAsync(connection, transaction, tenantId, cancellationToken);
        await DeleteExistingEnrollmentDocumentsAsync(connection, transaction, tenantId, document.EnrollmentId, cancellationToken);
        var documentId = await InsertClinicalDocumentAsync(connection, transaction, tenantId, document, cancellationToken);
        await InsertDocumentChunkAsync(connection, transaction, tenantId, documentId, document, cancellationToken);

        await transaction.CommitAsync(cancellationToken);
        _logger.LogDebug(
            "Saved enrollment grounding document {EnrollmentId} for NPI {Npi} into HorizonDB",
            document.EnrollmentId,
            document.Npi);
    }

    public async Task<IReadOnlyList<ClinicalGroundingSnippet>> SearchGroundingDocumentsAsync(
        string tenantCode,
        string prescriberNpi,
        float[] embedding,
        int maxCount = 5,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_options.ConnectionString))
        {
            throw new InvalidOperationException(
                "HorizonDb:ConnectionString is not configured. Supply it via environment variables or a secure secret store.");
        }

        var snippets = new List<ClinicalGroundingSnippet>(maxCount);
        var embeddingLiteral = $"[{string.Join(',', embedding.Select(value => value.ToString(CultureInfo.InvariantCulture)))}]";

        await using var connection = new NpgsqlConnection(_options.ConnectionString);
        await connection.OpenAsync(cancellationToken);
        await using var transaction = await connection.BeginTransactionAsync(cancellationToken);

        var tenantId = await ResolveTenantIdAsync(connection, transaction, tenantCode, cancellationToken);
        if (tenantId is null)
        {
            _logger.LogWarning("HorizonDB tenant '{TenantCode}' was not found. Returning empty grounding result set.", tenantCode);
            await transaction.CommitAsync(cancellationToken);
            return snippets.AsReadOnly();
        }

        var resolvedTenantId = tenantId.Value;
        await SetTenantContextAsync(connection, transaction, resolvedTenantId, cancellationToken);

        const string sql = """
            SELECT
                dc.chunk_id::text,
                dc.document_id::text,
                cd.title,
                dc.content_text,
                1 - (dc.embedding <=> CAST(@embedding AS vector)) AS similarity,
                dc.embedding_model
            FROM clinical.document_chunks dc
            INNER JOIN clinical.clinical_documents cd ON cd.document_id = dc.document_id
            WHERE dc.tenant_id = @tenant_id
              AND dc.embedding IS NOT NULL
                            AND (@npi = '' OR dc.metadata ->> 'npi' = @npi OR COALESCE(dc.metadata ->> 'npi', '') = '')
            ORDER BY dc.embedding <=> CAST(@embedding AS vector)
            LIMIT @max_count;
            """;

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("embedding", embeddingLiteral);
        command.Parameters.AddWithValue("tenant_id", resolvedTenantId);
        command.Parameters.AddWithValue("npi", prescriberNpi ?? string.Empty);
        command.Parameters.AddWithValue("max_count", maxCount);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            snippets.Add(new ClinicalGroundingSnippet(
                reader.GetString(0),
                reader.GetString(1),
                reader.GetString(2),
                reader.GetString(3),
                reader.GetDouble(4),
                reader.IsDBNull(5) ? null : reader.GetString(5)));
        }

        await transaction.CommitAsync(cancellationToken);

        return snippets.AsReadOnly();
    }

    private static async Task<Guid?> ResolveTenantIdAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        string tenantCode,
        CancellationToken cancellationToken)
    {
        const string sql = """
            SELECT tenant_id
            FROM clinical.tenants
            WHERE tenant_code = @tenant_code;
            """;

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("tenant_code", tenantCode);

        var tenantId = await command.ExecuteScalarAsync(cancellationToken);
        return tenantId is Guid resolvedTenantId ? resolvedTenantId : null;
    }

    private static async Task SetTenantContextAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        Guid tenantId,
        CancellationToken cancellationToken)
    {
        const string sql = "SELECT set_config(@setting_name, @setting_value, true);";

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("setting_name", TenantContextSetting);
        command.Parameters.AddWithValue("setting_value", tenantId.ToString());

        await command.ExecuteScalarAsync(cancellationToken);
    }

    private static async Task<Guid> UpsertTenantAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        EnrollmentGroundingDocument document,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO clinical.tenants (tenant_id, tenant_code, display_name, region_code)
            VALUES (@tenant_id, @tenant_code, @display_name, @region_code)
            ON CONFLICT (tenant_code) DO UPDATE
            SET display_name = EXCLUDED.display_name,
                region_code = EXCLUDED.region_code
            RETURNING tenant_id;
            """;

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("tenant_id", Guid.NewGuid());
        command.Parameters.AddWithValue("tenant_code", document.TenantCode);
        command.Parameters.AddWithValue("display_name", "Caldova HCP Portal");
        command.Parameters.AddWithValue("region_code", "us");

        return (Guid)(await command.ExecuteScalarAsync(cancellationToken)
            ?? throw new InvalidOperationException("Failed to upsert HorizonDB tenant."));
    }

    private static async Task<Guid> InsertClinicalDocumentAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        Guid tenantId,
        EnrollmentGroundingDocument document,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO clinical.clinical_documents
                (tenant_id, document_type, title, source_system, authored_utc, raw_text, metadata)
            VALUES
                (@tenant_id, @document_type, @title, @source_system, @authored_utc, @raw_text, CAST(@metadata AS jsonb))
            RETURNING document_id;
            """;

        var metadata = JsonSerializer.Serialize(new
        {
            source = "physician-enrollment",
            enrollmentId = document.EnrollmentId,
            npi = document.Npi,
            organization = document.OrganizationName,
            specialty = document.Specialty
        });

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("document_type", "physician-enrollment");
        command.Parameters.AddWithValue("title", $"Prescriber enrollment {document.Npi}");
        command.Parameters.AddWithValue("source_system", "hcp-portal");
        command.Parameters.AddWithValue("authored_utc", document.CreatedUtc.UtcDateTime);
        command.Parameters.AddWithValue("raw_text", document.ContentText);
        command.Parameters.AddWithValue("metadata", metadata);

        return (Guid)(await command.ExecuteScalarAsync(cancellationToken)
            ?? throw new InvalidOperationException("Failed to insert HorizonDB clinical document."));
    }

    private static async Task DeleteExistingEnrollmentDocumentsAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        Guid tenantId,
        Guid enrollmentId,
        CancellationToken cancellationToken)
    {
        const string sql = """
            DELETE FROM clinical.clinical_documents cd
            WHERE cd.tenant_id = @tenant_id
              AND cd.metadata ->> 'source' = 'physician-enrollment'
              AND cd.metadata ->> 'enrollmentId' = @enrollment_id;
            """;

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("enrollment_id", enrollmentId.ToString());
        await command.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task InsertDocumentChunkAsync(
        NpgsqlConnection connection,
        NpgsqlTransaction transaction,
        Guid tenantId,
        Guid documentId,
        EnrollmentGroundingDocument document,
        CancellationToken cancellationToken)
    {
        const string sql = """
            INSERT INTO clinical.document_chunks
                (document_id, tenant_id, chunk_ordinal, content_text, token_count, embedding, embedding_model, metadata)
            VALUES
                (@document_id, @tenant_id, @chunk_ordinal, @content_text, @token_count,
                 CASE WHEN @embedding IS NULL THEN NULL ELSE CAST(@embedding AS vector) END,
                 @embedding_model, CAST(@metadata AS jsonb));
            """;

        var metadata = JsonSerializer.Serialize(new
        {
            source = "physician-enrollment",
            enrollmentId = document.EnrollmentId,
            npi = document.Npi
        });

        var embeddingLiteral = document.Embedding is null
            ? null
            : $"[{string.Join(',', document.Embedding.Select(value => value.ToString(CultureInfo.InvariantCulture)))}]";

        var tokenCount = Math.Max(1, document.ContentText.Split(' ', StringSplitOptions.RemoveEmptyEntries).Length);

        await using var command = new NpgsqlCommand(sql, connection, transaction);
        command.Parameters.AddWithValue("document_id", documentId);
        command.Parameters.AddWithValue("tenant_id", tenantId);
        command.Parameters.AddWithValue("chunk_ordinal", 0);
        command.Parameters.AddWithValue("content_text", document.ContentText);
        command.Parameters.AddWithValue("token_count", tokenCount);
        command.Parameters.AddWithValue("embedding", embeddingLiteral is null ? DBNull.Value : embeddingLiteral);
        command.Parameters.AddWithValue("embedding_model", document.EmbeddingModel is null ? DBNull.Value : document.EmbeddingModel);
        command.Parameters.AddWithValue("metadata", metadata);

        await command.ExecuteNonQueryAsync(cancellationToken);
    }
}