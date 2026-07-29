using HcpPortalApi.Application;
using HcpPortalApi.Infrastructure;
using HcpPortalApi.Worker;

var builder = Host.CreateApplicationBuilder(args);

builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);
builder.Services.AddHostedService<EnrollmentEventWorker>();

var host = builder.Build();
await host.RunAsync();
