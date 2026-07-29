using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface IEnrollmentEventPublisher
{
    Task PublishEnrollmentCreatedAsync(EnrollmentCreatedEvent enrollmentEvent, CancellationToken cancellationToken);
}