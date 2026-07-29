namespace HcpPortalApi.Infrastructure.Options;

public sealed class ServiceBusOptions
{
    public const string SectionName = "ServiceBus";

    public string? FullyQualifiedNamespace { get; init; }

    public string QueueName { get; init; } = "enrollment-events";
}