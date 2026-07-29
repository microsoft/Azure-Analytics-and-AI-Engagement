using Azure.Messaging.ServiceBus;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.DTOs;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Options;
using System.Text.Json;

namespace HcpPortalApi.Infrastructure.Messaging;

public sealed class ServiceBusEnrollmentEventPublisher : IEnrollmentEventPublisher
{
    private readonly ServiceBusClient _serviceBusClient;
    private readonly ServiceBusOptions _options;

    public ServiceBusEnrollmentEventPublisher(
        ServiceBusClient serviceBusClient,
        IOptions<ServiceBusOptions> options)
    {
        _serviceBusClient = serviceBusClient;
        _options = options.Value;
    }

    public async Task PublishEnrollmentCreatedAsync(
        EnrollmentCreatedEvent enrollmentEvent,
        CancellationToken cancellationToken)
    {
        await using var sender = _serviceBusClient.CreateSender(_options.QueueName);

        var body = JsonSerializer.Serialize(enrollmentEvent);

        var message = new ServiceBusMessage(body)
        {
            ContentType = "application/json",
            Subject = "physician.enrollment.created",
            MessageId = enrollmentEvent.EnrollmentId.ToString()
        };

        await sender.SendMessageAsync(message, cancellationToken);
    }
}