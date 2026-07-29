using HcpPortalApi.Application.DTOs;

namespace HcpPortalApi.Application.Abstractions;

public interface ISandboxSessionService
{
    Task<SandboxSession> CreateAsync(string prescriberNpi, CancellationToken cancellationToken);
    Task<SandboxSession?> GetAsync(Guid sessionId, CancellationToken cancellationToken);
    Task<SandboxSession?> GetActiveByPrescriberAsync(string prescriberNpi, CancellationToken cancellationToken);
    Task<IReadOnlyList<SandboxSession>> ListActiveAsync(CancellationToken cancellationToken);
    Task<bool> EndAsync(Guid sessionId, CancellationToken cancellationToken);
}
