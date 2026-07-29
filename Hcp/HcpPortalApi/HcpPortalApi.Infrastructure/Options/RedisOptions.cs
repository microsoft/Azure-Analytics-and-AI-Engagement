namespace HcpPortalApi.Infrastructure.Options;

public sealed class RedisOptions
{
    public const string SectionName = "Redis";

    public string? ConnectionString { get; init; }

    /// <summary>Default cache entry lifetime in seconds.</summary>
    public int DefaultExpirySeconds { get; init; } = 300;
}
