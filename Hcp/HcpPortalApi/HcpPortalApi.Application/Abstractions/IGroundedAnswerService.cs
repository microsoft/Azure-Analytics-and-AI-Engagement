using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface IGroundedAnswerService
{
    Task<string> GenerateAnswerAsync(
        ClinicianQuestionRequest request,
        IReadOnlyList<ClinicalGroundingSnippet> sourceDocuments,
        IReadOnlyList<AgentMemoryEntry> memories,
        IReadOnlyList<ConversationMessage> recentMessages,
        CancellationToken cancellationToken);
}
