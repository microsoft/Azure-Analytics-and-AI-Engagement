using Azure;
using Azure.AI.OpenAI;
using Azure.Identity;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HcpPortalApi.Infrastructure.AI;

public sealed class FoundryEmbeddingService : IEmbeddingService
{
    private readonly OpenAI.Embeddings.EmbeddingClient _client;
    private readonly ILogger<FoundryEmbeddingService> _logger;

    public FoundryEmbeddingService(IOptions<FoundryOptions> options, ILogger<FoundryEmbeddingService> logger)
    {
        _logger = logger;
        var opts = options.Value;

        if (string.IsNullOrWhiteSpace(opts.Endpoint))
            throw new InvalidOperationException(
                "Foundry:Endpoint is not configured. Set it to your Azure AI Foundry or Azure OpenAI endpoint.");

        var azureClient = new AzureOpenAIClient(new Uri(opts.Endpoint), new DefaultAzureCredential());

        _client = azureClient.GetEmbeddingClient(opts.EmbeddingModelDeployment);
    }

    public async Task<float[]> GenerateEmbeddingAsync(string text, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Generating embedding via Foundry for {Length}-character input", text.Length);
        var result = await _client.GenerateEmbeddingAsync(text, cancellationToken: cancellationToken);
        return result.Value.ToFloats().ToArray();
    }
}
