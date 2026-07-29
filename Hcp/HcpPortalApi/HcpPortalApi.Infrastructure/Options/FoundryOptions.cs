namespace HcpPortalApi.Infrastructure.Options;

public sealed class FoundryOptions
{
    public const string SectionName = "Foundry";

    /// <summary>Azure AI Foundry / Azure OpenAI endpoint, e.g. https://&lt;name&gt;.openai.azure.com/</summary>
    public string? Endpoint { get; init; }

    /// <summary>Deployment name for the text embedding model.</summary>
    public string EmbeddingModelDeployment { get; init; } = "text-embedding-3-small";

    /// <summary>Deployment name for the chat/completions model used to synthesize grounded answers.</summary>
    public string ChatModelDeployment { get; init; } = "gpt-4o-mini";
}
