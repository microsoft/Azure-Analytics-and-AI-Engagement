using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Application.Services;
using Microsoft.Extensions.DependencyInjection;

namespace HcpPortalApi.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddScoped<IPhysicianEnrollmentService, PhysicianEnrollmentService>();
        services.AddScoped<IClinicianAssistantService, ClinicianAssistantService>();
        return services;
    }
}