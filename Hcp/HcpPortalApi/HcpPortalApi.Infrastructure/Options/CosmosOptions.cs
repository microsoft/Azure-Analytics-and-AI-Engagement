namespace HcpPortalApi.Infrastructure.Options;

public sealed class CosmosOptions
{
    public const string SectionName = "Cosmos";

    /// <summary>Cosmos DB account endpoint URI. Used with DefaultAzureCredential when set.</summary>
    public string? AccountEndpoint { get; init; }

    public string DatabaseName { get; init; } = "hcp-ai-memory";
    public string ConversationMessagesContainer { get; init; } = "conversationMessages";
    public string AgentMemoriesContainer { get; init; } = "agentMemories";
}
