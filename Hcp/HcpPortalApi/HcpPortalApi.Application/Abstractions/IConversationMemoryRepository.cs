using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface IConversationMemoryRepository
{
    Task SaveConversationMessageAsync(ConversationMessage message, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<ConversationMessage>> GetRecentMessagesAsync(
        string conversationKey,
        int maxCount = 20,
        CancellationToken cancellationToken = default);

    Task SaveAgentMemoryAsync(AgentMemoryEntry memory, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AgentMemoryEntry>> GetAgentMemoriesAsync(
        string memoryKey,
        int maxCount = 10,
        CancellationToken cancellationToken = default);
}
