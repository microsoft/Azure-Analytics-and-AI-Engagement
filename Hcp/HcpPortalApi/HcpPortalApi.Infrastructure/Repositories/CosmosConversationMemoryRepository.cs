using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Azure.Cosmos;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HcpPortalApi.Infrastructure.Repositories;

public sealed class CosmosConversationMemoryRepository : IConversationMemoryRepository
{
    private readonly CosmosClient _client;
    private readonly CosmosOptions _options;
    private readonly ILogger<CosmosConversationMemoryRepository> _logger;

    public CosmosConversationMemoryRepository(
        CosmosClient client,
        IOptions<CosmosOptions> options,
        ILogger<CosmosConversationMemoryRepository> logger)
    {
        _client = client;
        _options = options.Value;
        _logger = logger;
    }

    public async Task SaveConversationMessageAsync(ConversationMessage message, CancellationToken cancellationToken = default)
    {
        var container = _client.GetContainer(_options.DatabaseName, _options.ConversationMessagesContainer);
        await container.UpsertItemAsync(message, new PartitionKey(message.ConversationKey), cancellationToken: cancellationToken);
        _logger.LogDebug("Saved conversation message {Id} to Cosmos container {Container}", message.Id, _options.ConversationMessagesContainer);
    }

    public async Task<IReadOnlyList<ConversationMessage>> GetRecentMessagesAsync(
        string conversationKey,
        int maxCount = 20,
        CancellationToken cancellationToken = default)
    {
        var container = _client.GetContainer(_options.DatabaseName, _options.ConversationMessagesContainer);
        var query = new QueryDefinition(
            "SELECT * FROM c WHERE c.conversationKey = @key ORDER BY c.sequence DESC")
            .WithParameter("@key", conversationKey);

        var requestOptions = new QueryRequestOptions
        {
            PartitionKey = new PartitionKey(conversationKey),
            MaxItemCount = maxCount
        };

        var results = new List<ConversationMessage>(maxCount);
        using var iterator = container.GetItemQueryIterator<ConversationMessage>(query, requestOptions: requestOptions);

        // Read only the first page — MaxItemCount bounds the result set.
        if (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(cancellationToken);
            results.AddRange(page);
        }

        return results.AsReadOnly();
    }

    public async Task SaveAgentMemoryAsync(AgentMemoryEntry memory, CancellationToken cancellationToken = default)
    {
        var container = _client.GetContainer(_options.DatabaseName, _options.AgentMemoriesContainer);
        await container.UpsertItemAsync(memory, new PartitionKey(memory.MemoryKey), cancellationToken: cancellationToken);
        _logger.LogDebug("Saved agent memory {Id} to Cosmos container {Container}", memory.Id, _options.AgentMemoriesContainer);
    }

    public async Task<IReadOnlyList<AgentMemoryEntry>> GetAgentMemoriesAsync(
        string memoryKey,
        int maxCount = 10,
        CancellationToken cancellationToken = default)
    {
        var container = _client.GetContainer(_options.DatabaseName, _options.AgentMemoriesContainer);
        var query = new QueryDefinition(
            "SELECT * FROM c WHERE c.memoryKey = @key AND (IS_NULL(c.expiresUtc) OR c.expiresUtc > GetCurrentDateTime()) ORDER BY c.importance DESC, c.updatedUtc DESC")
            .WithParameter("@key", memoryKey);

        var requestOptions = new QueryRequestOptions
        {
            PartitionKey = new PartitionKey(memoryKey),
            MaxItemCount = maxCount
        };

        var results = new List<AgentMemoryEntry>(maxCount);
        using var iterator = container.GetItemQueryIterator<AgentMemoryEntry>(query, requestOptions: requestOptions);

        if (iterator.HasMoreResults)
        {
            var page = await iterator.ReadNextAsync(cancellationToken);
            results.AddRange(page);
        }

        return results.AsReadOnly();
    }
}
