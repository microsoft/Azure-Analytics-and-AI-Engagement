using System.Text;
using Azure.AI.OpenAI;
using Azure.Identity;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Options;
using OpenAI.Chat;

namespace HcpPortalApi.Infrastructure.AI;

public sealed class FoundryGroundedAnswerService : IGroundedAnswerService
{
    private readonly ChatClient _chatClient;

    public FoundryGroundedAnswerService(IOptions<FoundryOptions> options)
    {
        var opts = options.Value;

        if (string.IsNullOrWhiteSpace(opts.Endpoint))
            throw new InvalidOperationException(
                "Foundry:Endpoint is not configured. Set it to your Azure AI Foundry or Azure OpenAI endpoint.");

        var azureClient = new AzureOpenAIClient(new Uri(opts.Endpoint), new DefaultAzureCredential());
        _chatClient = azureClient.GetChatClient(opts.ChatModelDeployment);
    }

    public async Task<string> GenerateAnswerAsync(
        ClinicianQuestionRequest request,
        IReadOnlyList<ClinicalGroundingSnippet> sourceDocuments,
        IReadOnlyList<AgentMemoryEntry> memories,
        IReadOnlyList<ConversationMessage> recentMessages,
        CancellationToken cancellationToken)
    {
        var contextBlock = BuildContextBlock(request, sourceDocuments, memories, recentMessages);

        var messages = new List<ChatMessage>
        {
            new SystemChatMessage(
                "You are a clinical assistant for prescribers. Answer only using the provided grounded context. " +
                "If grounded context is insufficient, state that clearly and do not invent facts."),
            new UserChatMessage(contextBlock)
        };

        var completion = await _chatClient.CompleteChatAsync(messages, cancellationToken: cancellationToken);
        var answer = completion.Value.Content.FirstOrDefault()?.Text?.Trim();

        if (string.IsNullOrWhiteSpace(answer))
        {
            throw new InvalidOperationException("Foundry chat completion returned an empty assistant response.");
        }

        return answer;
    }

    private static string BuildContextBlock(
        ClinicianQuestionRequest request,
        IReadOnlyList<ClinicalGroundingSnippet> sourceDocuments,
        IReadOnlyList<AgentMemoryEntry> memories,
        IReadOnlyList<ConversationMessage> recentMessages)
    {
        var builder = new StringBuilder();
        builder.AppendLine("User question:");
        builder.AppendLine(request.Question);
        builder.AppendLine();
        builder.AppendLine($"Tenant: {request.TenantId}");
        builder.AppendLine($"Prescriber NPI: {request.PrescriberNpi}");
        builder.AppendLine();

        builder.AppendLine("Grounding snippets:");
        if (sourceDocuments.Count == 0)
        {
            builder.AppendLine("- NONE");
        }
        else
        {
            for (var i = 0; i < sourceDocuments.Count; i++)
            {
                var snippet = sourceDocuments[i];
                builder.AppendLine($"- [{i + 1}] {snippet.Title} (similarity: {snippet.Similarity:F3})");
                builder.AppendLine($"  {snippet.ContentText}");
            }
        }

        builder.AppendLine();
        builder.AppendLine("Long-term memory summaries:");
        if (memories.Count == 0)
        {
            builder.AppendLine("- NONE");
        }
        else
        {
            foreach (var memory in memories)
            {
                builder.AppendLine($"- {memory.Summary}");
            }
        }

        builder.AppendLine();
        builder.AppendLine("Recent conversation messages:");
        if (recentMessages.Count == 0)
        {
            builder.AppendLine("- NONE");
        }
        else
        {
            foreach (var message in recentMessages.OrderBy(m => m.Sequence))
            {
                builder.AppendLine($"- {message.Role}: {message.Content}");
            }
        }

        builder.AppendLine();
        builder.AppendLine("Return a concise clinical answer and cite snippet indices like [1], [2] when used.");

        return builder.ToString();
    }
}
