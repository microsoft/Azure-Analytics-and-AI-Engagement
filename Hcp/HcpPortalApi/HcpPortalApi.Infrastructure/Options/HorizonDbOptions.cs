namespace HcpPortalApi.Infrastructure.Options;

public sealed class HorizonDbOptions
{
    public const string SectionName = "HorizonDb";

    public string? ConnectionString { get; init; }
}