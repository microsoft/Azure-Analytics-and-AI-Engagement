using System.Text.Json;
using HcpPortalApi.Application.Abstractions;
using HcpPortalApi.Infrastructure.Options;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HcpPortalApi.Infrastructure.Caching;

public sealed class RedisResponseCache : IResponseCache
{
    private readonly IDistributedCache _cache;
    private readonly RedisOptions _options;
    private readonly ILogger<RedisResponseCache> _logger;

    public RedisResponseCache(
        IDistributedCache cache,
        IOptions<RedisOptions> options,
        ILogger<RedisResponseCache> logger)
    {
        _cache = cache;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default)
    {
        var bytes = await _cache.GetAsync(key, cancellationToken);
        if (bytes is null) return default;
        return JsonSerializer.Deserialize<T>(bytes);
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan? expiry = null, CancellationToken cancellationToken = default)
    {
        var bytes = JsonSerializer.SerializeToUtf8Bytes(value);
        var cacheEntryOptions = new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = expiry ?? TimeSpan.FromSeconds(_options.DefaultExpirySeconds)
        };
        await _cache.SetAsync(key, bytes, cacheEntryOptions, cancellationToken);
        _logger.LogDebug("Cached key {Key}, expires in {Seconds}s", key, cacheEntryOptions.AbsoluteExpirationRelativeToNow?.TotalSeconds);
    }

    public async Task RemoveAsync(string key, CancellationToken cancellationToken = default)
    {
        await _cache.RemoveAsync(key, cancellationToken);
        _logger.LogDebug("Evicted cache key {Key}", key);
    }
}
