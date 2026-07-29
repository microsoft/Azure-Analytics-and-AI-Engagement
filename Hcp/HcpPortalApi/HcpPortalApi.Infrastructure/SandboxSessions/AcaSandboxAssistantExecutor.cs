using System.Net.Http.Headers;
using System.Net.Http.Json;
using Azure.Core;
using Azure.Identity;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Options;

namespace HcpPortalApi.Infrastructure.SandboxSessions;

internal sealed class AcaSandboxAssistantExecutor : ISandboxAssistantExecutor
{
    private readonly HttpClient _httpClient;
    private readonly SandboxRuntimeOptions _options;
    private readonly TokenCredential _credential;

    public AcaSandboxAssistantExecutor(
        HttpClient httpClient,
        IOptions<SandboxRuntimeOptions> options,
        TokenCredential credential)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _credential = credential;

        if (string.IsNullOrWhiteSpace(_options.BaseUrlTemplate))
        {
            throw new InvalidOperationException("SandboxRuntime:BaseUrlTemplate is required for sandbox-executed assistant flow.");
        }
    }

    public async Task<ClinicianAnswerResponse> ExecuteAsync(
        ClinicianQuestionRequest request,
        SandboxSession session,
        CancellationToken cancellationToken)
    {
        var baseUrl = _options.BaseUrlTemplate!
            .Replace("{sandboxId}", Uri.EscapeDataString(session.SandboxId), StringComparison.OrdinalIgnoreCase)
            .Replace("{sandboxGroup}", Uri.EscapeDataString(session.SandboxGroupName), StringComparison.OrdinalIgnoreCase)
            .TrimEnd('/');

        using var message = new HttpRequestMessage(HttpMethod.Post, $"{baseUrl}{NormalizePath(_options.AssistantQueryPath)}")
        {
            Content = JsonContent.Create(new
            {
                tenantId = request.TenantId,
                prescriberNpi = request.PrescriberNpi,
                question = request.Question,
                conversationId = request.ConversationId
            })
        };

        if (!string.IsNullOrWhiteSpace(_options.Audience))
        {
            var token = await _credential.GetTokenAsync(new TokenRequestContext([_options.Audience]), cancellationToken);
            message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);
        }

        using var response = await _httpClient.SendAsync(message, cancellationToken);
        var payload = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"Sandbox assistant execution failed for sandbox '{session.SandboxId}'. Status={(int)response.StatusCode}, Body={payload}");
        }

        var result = System.Text.Json.JsonSerializer.Deserialize<ClinicianAnswerResponse>(payload, new System.Text.Json.JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        return result ?? throw new InvalidOperationException("Sandbox assistant execution returned an empty/invalid response payload.");
    }

    private static string NormalizePath(string relativePath)
    {
        if (string.IsNullOrWhiteSpace(relativePath))
        {
            return "/api/assistant/query";
        }

        return relativePath.StartsWith('/') ? relativePath : $"/{relativePath}";
    }
}
