using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using System.Text.Json;
using System.Collections.Concurrent;
using Azure.Core;
using Azure.Identity;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HcpPortalApi.Infrastructure.SandboxSessions;

internal sealed class AcaSandboxSessionService : ISandboxSessionService
{
    private static readonly ConcurrentDictionary<Guid, SandboxSession> SessionPoolSessions = new();

    private readonly HttpClient _httpClient;
    private readonly SandboxGroupOptions _options;
    private readonly SessionPoolOptions _sessionPoolOptions;
    private readonly TokenCredential _credential;
    private readonly ILogger<AcaSandboxSessionService> _logger;

    public AcaSandboxSessionService(
        HttpClient httpClient,
        IOptions<SandboxGroupOptions> options,
        IOptions<SessionPoolOptions> sessionPoolOptions,
        ILogger<AcaSandboxSessionService> logger,
        TokenCredential? credential = null)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _sessionPoolOptions = sessionPoolOptions.Value;
        _logger = logger;
        _credential = credential ?? new DefaultAzureCredential();

        if (_sessionPoolOptions.IsConfigured)
        {
            _httpClient.BaseAddress = new Uri(_sessionPoolOptions.ManagementEndpoint!.TrimEnd('/'));
            return;
        }

        if (string.IsNullOrWhiteSpace(_options.Name))
        {
            throw new InvalidOperationException("SandboxGroup:Name is required for real sandbox provisioning.");
        }

        if (string.IsNullOrWhiteSpace(_options.ManagementEndpoint))
        {
            throw new InvalidOperationException("SandboxGroup:ManagementEndpoint is required for real sandbox provisioning.");
        }

        _httpClient.BaseAddress = new Uri(_options.ManagementEndpoint.TrimEnd('/'));
    }

    public async Task<SandboxSession> CreateAsync(string prescriberNpi, CancellationToken cancellationToken)
    {
        var sessionId = Guid.NewGuid();
        var createName = $"hcp-{sessionId:N}";

        if (_sessionPoolOptions.IsConfigured)
        {
            try
            {
                await ExecuteSessionPoolWarmupAsync(createName, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex,
                    "SessionPool warmup failed for {SessionIdentifier}. Creating logical session record for API workflow continuity.",
                    createName);
            }

            var created = new SandboxSession(
                sessionId,
                prescriberNpi,
                createName,
                _sessionPoolOptions.ManagementEndpoint ?? string.Empty,
                _sessionPoolOptions.ManagementEndpoint ?? string.Empty,
                "Ready",
                DateTimeOffset.UtcNow,
                null);

            SessionPoolSessions[sessionId] = created;
            return created;
        }

        var body = new
        {
            name = createName,
            properties = new
            {
                labels = new Dictionary<string, string>
                {
                    ["sessionId"] = sessionId.ToString(),
                    ["prescriberNpi"] = prescriberNpi
                }
            }
        };

        string payload;
        using var response = await CreateSandboxWithFallbackAsync(createName, body, cancellationToken);
        payload = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"Failed to create sandbox session. Status={(int)response.StatusCode}, Body={payload}");
        }

        var mapped = TryMapSessionFromPayload(payload, prescriberNpi, sessionId);
        if (mapped is null)
        {
            throw new InvalidOperationException("Sandbox create response did not contain a valid session payload.");
        }

        _logger.LogInformation("Created ACA sandbox {SandboxId} for prescriber {PrescriberNpi}.", mapped.SandboxId, prescriberNpi);
        return mapped;
    }

    private async Task<HttpResponseMessage> CreateSandboxWithFallbackAsync(string createName, object body, CancellationToken cancellationToken)
    {
        using var postRequest = await CreateAuthorizedRequestAsync(HttpMethod.Post, BuildCollectionPath(), cancellationToken);
        postRequest.Content = JsonContent.Create(body);

        var postResponse = await _httpClient.SendAsync(postRequest, cancellationToken);
        if (postResponse.IsSuccessStatusCode)
        {
            return postResponse;
        }

        if (postResponse.StatusCode is not (System.Net.HttpStatusCode.NotFound or System.Net.HttpStatusCode.MethodNotAllowed))
        {
            return postResponse;
        }

        postResponse.Dispose();

        using var putRequest = await CreateAuthorizedRequestAsync(HttpMethod.Put, BuildItemPath(createName), cancellationToken);
        putRequest.Content = JsonContent.Create(body);

        return await _httpClient.SendAsync(putRequest, cancellationToken);
    }

    public async Task<SandboxSession?> GetAsync(Guid sessionId, CancellationToken cancellationToken)
    {
        if (_sessionPoolOptions.IsConfigured)
        {
            return SessionPoolSessions.TryGetValue(sessionId, out var existing) ? existing : null;
        }

        var active = await ListActiveAsync(cancellationToken);
        return active.FirstOrDefault(s => s.SessionId == sessionId);
    }

    public async Task<SandboxSession?> GetActiveByPrescriberAsync(string prescriberNpi, CancellationToken cancellationToken)
    {
        if (_sessionPoolOptions.IsConfigured)
        {
            return SessionPoolSessions.Values
                .Where(s => s.EndedAt is null)
                .OrderByDescending(s => s.CreatedAt)
                .FirstOrDefault(s => string.Equals(s.PrescriberNpi, prescriberNpi, StringComparison.OrdinalIgnoreCase));
        }

        var active = await ListActiveAsync(cancellationToken);
        return active.FirstOrDefault(s =>
            s.EndedAt is null &&
            string.Equals(s.PrescriberNpi, prescriberNpi, StringComparison.OrdinalIgnoreCase));
    }

    public async Task<IReadOnlyList<SandboxSession>> ListActiveAsync(CancellationToken cancellationToken)
    {
        if (_sessionPoolOptions.IsConfigured)
        {
            return SessionPoolSessions.Values
                .Where(s => s.EndedAt is null)
                .OrderByDescending(s => s.CreatedAt)
                .ToArray();
        }

        using var request = await CreateAuthorizedRequestAsync(HttpMethod.Get, BuildCollectionPath(), cancellationToken);
        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var payload = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"Failed to list sandboxes. Status={(int)response.StatusCode}, Body={payload}");
        }

        using var doc = JsonDocument.Parse(payload);
        var root = doc.RootElement;

        var sessions = new List<SandboxSession>();

        if (root.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in root.EnumerateArray())
            {
                var mapped = TryMapSession(item);
                if (mapped is not null && mapped.EndedAt is null)
                {
                    sessions.Add(mapped);
                }
            }
        }
        else if (root.TryGetProperty("value", out var value) && value.ValueKind == JsonValueKind.Array)
        {
            foreach (var item in value.EnumerateArray())
            {
                var mapped = TryMapSession(item);
                if (mapped is not null && mapped.EndedAt is null)
                {
                    sessions.Add(mapped);
                }
            }
        }

        return sessions
            .OrderByDescending(s => s.CreatedAt)
            .ToArray();
    }

    public async Task<bool> EndAsync(Guid sessionId, CancellationToken cancellationToken)
    {
        if (_sessionPoolOptions.IsConfigured)
        {
            SessionPoolSessions.TryRemove(sessionId, out _);
            return true;
        }

        var session = await GetAsync(sessionId, cancellationToken);
        if (session is null)
        {
            return false;
        }

        using var request = await CreateAuthorizedRequestAsync(HttpMethod.Delete, BuildItemPath(session.SandboxId), cancellationToken);
        using var response = await _httpClient.SendAsync(request, cancellationToken);

        if (response.IsSuccessStatusCode || response.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            _logger.LogInformation("Ended ACA sandbox {SandboxId} for session {SessionId}.", session.SandboxId, session.SessionId);
            return true;
        }

        var payload = await response.Content.ReadAsStringAsync(cancellationToken);
        throw new InvalidOperationException($"Failed to end sandbox session {sessionId}. Status={(int)response.StatusCode}, Body={payload}");
    }

    private async Task<HttpRequestMessage> CreateAuthorizedRequestAsync(HttpMethod method, string relativePath, CancellationToken cancellationToken)
    {
        var audience = _sessionPoolOptions.IsConfigured
            ? _sessionPoolOptions.Audience
            : _options.Audience;

        var token = await _credential.GetTokenAsync(new TokenRequestContext([audience]), cancellationToken);

        var request = new HttpRequestMessage(method, relativePath);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);
        return request;
    }

    private async Task ExecuteSessionPoolWarmupAsync(string identifier, CancellationToken cancellationToken)
    {
        var requestPath = BuildSessionPoolExecutionPath(identifier);

        var body = new SessionPoolExecutionRequest(
            CodeInputType: "inline",
            ExecutionType: "synchronous",
            Code: _sessionPoolOptions.WarmupCode,
            TimeoutInSeconds: 60);

        using var request = await CreateAuthorizedRequestAsync(HttpMethod.Post, requestPath, cancellationToken);
        request.Content = JsonContent.Create(body);

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var payload = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Failed to create session via SessionPool execution. Status={(int)response.StatusCode}, Body={payload}");
        }
    }

    private string BuildSessionPoolExecutionPath(string identifier)
    {
        var encodedIdentifier = Uri.EscapeDataString(identifier);
        var path = $"executions?identifier={encodedIdentifier}";
        return AppendApiVersion(path, _sessionPoolOptions.ApiVersion);
    }

    private string BuildCollectionPath()
    {
        var raw = _options.CollectionPathTemplate
            .Replace("{group}", Uri.EscapeDataString(_options.Name!), StringComparison.OrdinalIgnoreCase)
            .TrimStart('/');

        return AppendApiVersion(raw);
    }

    private string BuildItemPath(string sandboxId)
    {
        var raw = _options.ItemPathTemplate
            .Replace("{group}", Uri.EscapeDataString(_options.Name!), StringComparison.OrdinalIgnoreCase)
            .Replace("{sandboxId}", Uri.EscapeDataString(sandboxId), StringComparison.OrdinalIgnoreCase)
            .TrimStart('/');

        return AppendApiVersion(raw);
    }

    private string AppendApiVersion(string path)
    {
        return AppendApiVersion(path, _options.ApiVersion);
    }

    private static string AppendApiVersion(string path, string apiVersion)
    {
        var separator = path.Contains('?', StringComparison.Ordinal) ? '&' : '?';
        return $"{path}{separator}api-version={Uri.EscapeDataString(apiVersion)}";
    }

    private SandboxSession? TryMapSessionFromPayload(string payload, string prescriberNpi, Guid fallbackSessionId)
    {
        using var doc = JsonDocument.Parse(payload);
        var mapped = TryMapSession(doc.RootElement);
        if (mapped is not null)
        {
            return mapped;
        }

        if (doc.RootElement.TryGetProperty("name", out var nameElement))
        {
            var sandboxId = nameElement.GetString();
            if (!string.IsNullOrWhiteSpace(sandboxId))
            {
                return new SandboxSession(
                    fallbackSessionId,
                    prescriberNpi,
                    sandboxId,
                    _options.Name!,
                    _options.ManagementEndpoint!,
                    "Provisioning",
                    DateTimeOffset.UtcNow,
                    null);
            }
        }

        return null;
    }

    private SandboxSession? TryMapSession(JsonElement item)
    {
        string? sandboxId = null;
        string status = "Unknown";
        DateTimeOffset createdAt = DateTimeOffset.UtcNow;
        DateTimeOffset? endedAt = null;
        string? prescriberNpi = null;
        Guid sessionId = Guid.Empty;

        if (item.TryGetProperty("name", out var nameElement))
        {
            sandboxId = nameElement.GetString();
        }

        if (item.TryGetProperty("properties", out var properties))
        {
            if (properties.TryGetProperty("provisioningState", out var provisioningState))
            {
                status = provisioningState.GetString() ?? status;
            }

            if (properties.TryGetProperty("status", out var statusElement))
            {
                status = statusElement.GetString() ?? status;
            }

            if (properties.TryGetProperty("createdAt", out var createdAtElement) && createdAtElement.ValueKind == JsonValueKind.String)
            {
                if (DateTimeOffset.TryParse(createdAtElement.GetString(), out var parsedCreatedAt))
                {
                    createdAt = parsedCreatedAt;
                }
            }

            if (properties.TryGetProperty("endedAt", out var endedAtElement) && endedAtElement.ValueKind == JsonValueKind.String)
            {
                if (DateTimeOffset.TryParse(endedAtElement.GetString(), out var parsedEndedAt))
                {
                    endedAt = parsedEndedAt;
                }
            }

            if (properties.TryGetProperty("labels", out var labels) && labels.ValueKind == JsonValueKind.Object)
            {
                if (labels.TryGetProperty("prescriberNpi", out var npiElement))
                {
                    prescriberNpi = npiElement.GetString();
                }

                if (labels.TryGetProperty("sessionId", out var sessionElement))
                {
                    Guid.TryParse(sessionElement.GetString(), out sessionId);
                }
            }
        }

        if (string.IsNullOrWhiteSpace(sandboxId) || string.IsNullOrWhiteSpace(prescriberNpi) || sessionId == Guid.Empty)
        {
            return null;
        }

        return new SandboxSession(
            sessionId,
            prescriberNpi,
            sandboxId,
            _options.Name ?? string.Empty,
            _options.ManagementEndpoint ?? string.Empty,
            status,
            createdAt,
            endedAt);
    }

    private sealed record SessionPoolExecutionRequest(
        [property: JsonPropertyName("codeInputType")] string CodeInputType,
        [property: JsonPropertyName("executionType")] string ExecutionType,
        [property: JsonPropertyName("code")] string Code,
        [property: JsonPropertyName("timeoutInSeconds")] int TimeoutInSeconds);
}
