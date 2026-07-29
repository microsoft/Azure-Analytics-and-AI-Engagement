namespace HcpPortalApi.Application.DTOs;

public sealed record ClinicianAnswerResponse(
    string ConversationId,
    string GroundedAnswer,
    IReadOnlyList<ClinicalGroundingSnippet> SourceDocuments,
    IReadOnlyList<AgentMemoryEntry> AgentMemories,
    IReadOnlyList<ConversationMessage> RecentMessages);