import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const distDir = path.join(__dirname, 'dist');
const port = Number(process.env.PORT || 8080);
const apiUpstream = (process.env.API_UPSTREAM || 'http://hcp-portal-api/api').replace(/\/+$/, '');

const mimeTypes = {
  '.css': 'text/css; charset=utf-8',
  '.gif': 'image/gif',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain; charset=utf-8',
  '.webp': 'image/webp',
};

const hopByHopHeaders = new Set([
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
]);

const sendFile = async (response, filePath) => {
  const ext = path.extname(filePath).toLowerCase();
  const content = await readFile(filePath);
  response.writeHead(200, {
    'Content-Type': mimeTypes[ext] || 'application/octet-stream',
    'Cache-Control': ext === '.html' ? 'no-cache' : 'public, max-age=31536000, immutable',
  });
  response.end(content);
};

const proxyRequest = async (request, response) => {
  const targetUrl = new URL(`${apiUpstream}${request.url.replace(/^\/api/, '')}`);
  const headers = new Headers();

  for (const [key, value] of Object.entries(request.headers)) {
    if (typeof value === 'string' && !hopByHopHeaders.has(key.toLowerCase())) {
      headers.set(key, value);
    }
  }

  headers.set('x-forwarded-proto', request.headers['x-forwarded-proto'] || 'http');
  headers.set('x-forwarded-host', request.headers.host || '');

  const body = request.method === 'GET' || request.method === 'HEAD'
    ? undefined
    : await new Promise((resolve, reject) => {
        const chunks = [];
        request.on('data', chunk => chunks.push(chunk));
        request.on('end', () => resolve(Buffer.concat(chunks)));
        request.on('error', reject);
      });

  const upstreamResponse = await fetch(targetUrl, {
    method: request.method,
    headers,
    body,
    duplex: body ? 'half' : undefined,
    redirect: 'manual',
  });

  const responseHeaders = {};
  upstreamResponse.headers.forEach((value, key) => {
    if (!hopByHopHeaders.has(key.toLowerCase())) {
      responseHeaders[key] = value;
    }
  });

  response.writeHead(upstreamResponse.status, responseHeaders);
  const buffer = Buffer.from(await upstreamResponse.arrayBuffer());
  response.end(buffer);
};

createServer(async (request, response) => {
  try {
    const requestPath = new URL(request.url, `http://${request.headers.host || 'localhost'}`).pathname;

    if (requestPath === '/healthz') {
      response.writeHead(200, { 'Content-Type': 'text/plain; charset=utf-8' });
      response.end('ok');
      return;
    }

    if (requestPath.startsWith('/api/')) {
      await proxyRequest(request, response);
      return;
    }

    const normalizedPath = requestPath === '/' ? '/index.html' : requestPath;
    const candidatePath = path.normalize(path.join(distDir, normalizedPath));
    const safePath = candidatePath.startsWith(distDir) ? candidatePath : path.join(distDir, 'index.html');

    try {
      await sendFile(response, safePath);
    } catch {
      await sendFile(response, path.join(distDir, 'index.html'));
    }
  } catch (error) {
    response.writeHead(502, { 'Content-Type': 'application/json; charset=utf-8' });
    response.end(JSON.stringify({ error: 'frontend-proxy-failure', message: error instanceof Error ? error.message : 'Unknown error' }));
  }
}).listen(port, '0.0.0.0', () => {
  console.log(`hcp-portal-web listening on ${port}`);
});
