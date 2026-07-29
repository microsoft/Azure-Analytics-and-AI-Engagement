namespace HcpPortalApi.Application.DTOs;

public sealed record ClinicalGroundingSnippet(
    string ChunkId,
    string DocumentId,
    string Title,
    string ContentText,
    double Similarity,
    string? EmbeddingModel);