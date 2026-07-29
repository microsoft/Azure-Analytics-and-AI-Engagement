using System.Security.Cryptography;
using System.Text;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using Microsoft.Extensions.Logging;

namespace HcpPortalApi.Application.Services;

public sealed class ClinicianAssistantService : IClinicianAssistantService
{
    private const string AnswerCachePrefix = "clinician:answer:";
    private static readonly TimeSpan AnswerCacheTtl = TimeSpan.FromMinutes(10);

    private readonly IEmbeddingService _embeddingService;
    private readonly IClinicalGroundingRepository _groundingRepository;
    private readonly IConversationMemoryRepository _conversationMemoryRepository;
    private readonly IResponseCache _responseCache;
    private readonly IGroundedAnswerService _groundedAnswerService;
    private readonly ILogger<ClinicianAssistantService> _logger;

    public ClinicianAssistantService(
        IClinicalGroundingRepository groundingRepository,
        IEmbeddingService embeddingService,
        IConversationMemoryRepository conversationMemoryRepository,
        IResponseCache responseCache,
        IGroundedAnswerService groundedAnswerService,
        ILogger<ClinicianAssistantService> logger)
    {
        _groundingRepository = groundingRepository;
        _embeddingService = embeddingService;
        _conversationMemoryRepository = conversationMemoryRepository;
        _responseCache = responseCache;
        _groundedAnswerService = groundedAnswerService;
        _logger = logger;
    }

    public async Task<ClinicianAnswerResponse> AnswerAsync(ClinicianQuestionRequest request, CancellationToken cancellationToken)
    {
        var conversationId = string.IsNullOrWhiteSpace(request.ConversationId)
            ? Guid.NewGuid().ToString("N")
            : request.ConversationId;

        var memoryKey = $"{request.TenantId}|{request.PrescriberNpi}";
        var conversationKey = $"{request.TenantId}|{conversationId}";
        IReadOnlyList<AgentMemoryEntry> memories;
        try
        {
            memories = await _conversationMemoryRepository.GetAgentMemoriesAsync(memoryKey, cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Agent memory lookup failed for key {MemoryKey}. Continuing without memories.", memoryKey);
            memories = Array.Empty<AgentMemoryEntry>();
        }

        IReadOnlyList<ConversationMessage> recentMessages;
        try
        {
            recentMessages = await _conversationMemoryRepository.GetRecentMessagesAsync(conversationKey, cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Conversation history lookup failed for key {ConversationKey}. Continuing without history.", conversationKey);
            recentMessages = Array.Empty<ConversationMessage>();
        }

        var nextSequence = recentMessages.Count == 0 ? 1 : recentMessages.Max(message => message.Sequence) + 1;
        try
        {
            await _conversationMemoryRepository.SaveConversationMessageAsync(
                new ConversationMessage
                {
                    ConversationId = conversationId,
                    ConversationKey = conversationKey,
                    TenantId = request.TenantId,
                    Sequence = nextSequence,
                    Role = "user",
                    Content = request.Question,
                    SourceSystem = "clinician-assistant"
                },
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to persist user conversation message for conversation {ConversationId}.", conversationId);
        }

        var cacheKey = BuildAnswerCacheKey(request.TenantId, request.PrescriberNpi, request.Question);
        IReadOnlyList<ClinicalGroundingSnippet> sourceDocuments;
        string groundedAnswer;

        var cachedAnswer = await _responseCache.GetAsync<CachedAnswer>(cacheKey, cancellationToken);

        if (cachedAnswer is not null)
        {
            sourceDocuments = cachedAnswer.SourceDocuments;
            groundedAnswer = cachedAnswer.GroundedAnswer;
        }
        else
        {
            try
            {
                var queryEmbedding = await _embeddingService.GenerateEmbeddingAsync(request.Question, cancellationToken);
                sourceDocuments = await _groundingRepository.SearchGroundingDocumentsAsync(
                    request.TenantId,
                    request.PrescriberNpi,
                    queryEmbedding,
                    cancellationToken: cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Clinical grounding lookup failed for tenant {TenantId}, prescriber {PrescriberNpi}. Continuing with zero grounding documents.", request.TenantId, request.PrescriberNpi);
                sourceDocuments = Array.Empty<ClinicalGroundingSnippet>();
            }

            groundedAnswer = await _groundedAnswerService.GenerateAnswerAsync(
                request,
                sourceDocuments,
                memories,
                recentMessages,
                cancellationToken);

            try
            {
                await _responseCache.SetAsync(
                    cacheKey,
                    new CachedAnswer(groundedAnswer, sourceDocuments),
                    AnswerCacheTtl,
                    cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to cache answer for tenant {TenantId}, prescriber {PrescriberNpi}.", request.TenantId, request.PrescriberNpi);
            }
        }

        var answerSequence = recentMessages.Count == 0 ? 2 : recentMessages.Max(message => message.Sequence) + 2;
        try
        {
            await _conversationMemoryRepository.SaveConversationMessageAsync(
                new ConversationMessage
                {
                    ConversationId = conversationId,
                    ConversationKey = conversationKey,
                    TenantId = request.TenantId,
                    Sequence = answerSequence,
                    Role = "assistant",
                    Content = groundedAnswer,
                    SourceSystem = "clinician-assistant"
                },
                cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to persist assistant conversation message for conversation {ConversationId}.", conversationId);
        }

        try
        {
            recentMessages = await _conversationMemoryRepository.GetRecentMessagesAsync(conversationKey, cancellationToken: cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to reload conversation history for key {ConversationKey}. Returning available context.", conversationKey);
        }

        return new ClinicianAnswerResponse(
            conversationId,
            groundedAnswer,
            sourceDocuments,
            memories,
            recentMessages);
    }

    private static string BuildAnswerCacheKey(string tenantId, string prescriberNpi, string question)
    {
        var normalizedQuestion = question.Trim().ToLowerInvariant();
        var hash = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(normalizedQuestion)));
        return $"{AnswerCachePrefix}{tenantId}:{prescriberNpi}:{hash}";
    }

    private sealed record CachedAnswer(
        string GroundedAnswer,
        IReadOnlyList<ClinicalGroundingSnippet> SourceDocuments);
}