'use strict';

const fs = require('fs');
const path = require('path');
const http = require('http');
const { Readable } = require('stream');
const { pipeline } = require('stream/promises');
const { artifactPath, areaPrefix, normalizeRelativePath } = require('./lib/paths');

const config = {
  port: Number(process.env.PORT || '8080'),
  portalUser: process.env.PORTAL_USERNAME || 'user',
  portalPassword: process.env.PORTAL_PASSWORD || 'user',
  artifactoryBaseUrl: (process.env.ARTIFACTORY_BASE_URL || 'http://artifactory:8082').replace(/\/+$/, ''),
  artifactoryAdminUser: process.env.ARTIFACTORY_ADMIN_USER || 'admin',
  artifactoryAdminPassword: process.env.ARTIFACTORY_ADMIN_PASSWORD || 'Aa123456',
  repoKey: process.env.CONTENT_REPOSITORY_KEY || 'example-repo-local',
  firmwarePrefix: process.env.FIRMWARE_PREFIX || 'firmware',
  patchPrefix: process.env.PATCH_PREFIX || 'patch',
};

const publicDir = path.join(__dirname, 'public');

function json(res, statusCode, payload) {
  res.writeHead(statusCode, { 'Content-Type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(payload));
}

function unauthorized(res) {
  res.writeHead(401, {
    'WWW-Authenticate': 'Basic realm="JFrog LAN Portal"',
    'Content-Type': 'application/json; charset=utf-8',
  });
  res.end(JSON.stringify({ error: 'Authentication required.' }));
}

function authenticate(req, res) {
  if (req.url === '/api/health') {
    return true;
  }

  const authHeader = req.headers.authorization || '';
  if (!authHeader.startsWith('Basic ')) {
    unauthorized(res);
    return false;
  }

  const decoded = Buffer.from(authHeader.slice(6), 'base64').toString('utf8');
  const [username, password] = decoded.split(':');
  if (username !== config.portalUser || password !== config.portalPassword) {
    unauthorized(res);
    return false;
  }
  return true;
}

function adminAuthHeader() {
  return 'Basic ' + Buffer.from(`${config.artifactoryAdminUser}:${config.artifactoryAdminPassword}`).toString('base64');
}

async function artifactoryFetch(relativePath, options = {}) {
  const url = `${config.artifactoryBaseUrl}${relativePath}`;
  const headers = new Headers(options.headers || {});
  headers.set('Authorization', adminAuthHeader());
  return fetch(url, { ...options, headers });
}

async function serveStatic(req, res, pathname) {
  const safePath = pathname === '/' ? '/index.html' : pathname;
  const absolutePath = path.join(publicDir, safePath);
  if (!absolutePath.startsWith(publicDir)) {
    json(res, 403, { error: 'Forbidden path.' });
    return;
  }

  if (!fs.existsSync(absolutePath) || fs.statSync(absolutePath).isDirectory()) {
    json(res, 404, { error: 'Not found.' });
    return;
  }

  const contentType = absolutePath.endsWith('.css')
    ? 'text/css; charset=utf-8'
    : absolutePath.endsWith('.js')
      ? 'application/javascript; charset=utf-8'
      : 'text/html; charset=utf-8';

  res.writeHead(200, { 'Content-Type': contentType });
  fs.createReadStream(absolutePath).pipe(res);
}

function parseAreaAndPath(urlObject) {
  const area = urlObject.searchParams.get('area') || '';
  const relativePath = urlObject.searchParams.get('path') || '';
  return {
    area,
    relativePath,
  };
}

async function handleList(req, res, urlObject) {
  try {
    const { area, relativePath } = parseAreaAndPath(urlObject);
    const targetPath = artifactPath(area, relativePath, '', config);
    const query = new URLSearchParams({ list: '', deep: '0', listFolders: '1', mdTimestamps: '1' });
    const upstream = await artifactoryFetch(`/artifactory/api/storage/${targetPath}?${query.toString()}`);
    const payload = upstream.ok ? await upstream.json() : { files: [] };
    json(res, upstream.ok ? 200 : upstream.status, {
      area,
      path: normalizeRelativePath(relativePath),
      prefix: areaPrefix(area, config),
      files: payload.files || [],
    });
  } catch (error) {
    json(res, 400, { error: error.message });
  }
}

async function handleUpload(req, res, urlObject) {
  try {
    const { area, relativePath } = parseAreaAndPath(urlObject);
    const filename = urlObject.searchParams.get('filename') || '';
    if (!filename) {
      json(res, 400, { error: 'filename is required.' });
      return;
    }
    const upstream = await artifactoryFetch(
      `/artifactory/${artifactPath(area, relativePath, filename, config)}`,
      {
        method: 'PUT',
        headers: {
          'Content-Type': req.headers['content-type'] || 'application/octet-stream',
        },
        body: req,
        duplex: 'half',
      },
    );

    if (!upstream.ok) {
      json(res, upstream.status, { error: await upstream.text() });
      return;
    }

    json(res, 200, { ok: true, filename });
  } catch (error) {
    json(res, 400, { error: error.message });
  }
}

async function handleDownload(req, res, urlObject) {
  try {
    const { area, relativePath } = parseAreaAndPath(urlObject);
    const filename = urlObject.searchParams.get('filename') || '';
    if (!filename) {
      json(res, 400, { error: 'filename is required.' });
      return;
    }
    const upstream = await artifactoryFetch(
      `/artifactory/${artifactPath(area, relativePath, filename, config)}`,
      { method: 'GET' },
    );
    if (!upstream.ok || !upstream.body) {
      json(res, upstream.status, { error: await upstream.text() });
      return;
    }

    res.writeHead(200, {
      'Content-Type': upstream.headers.get('content-type') || 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${filename}"`,
    });
    await pipeline(Readable.fromWeb(upstream.body), res);
  } catch (error) {
    json(res, 400, { error: error.message });
  }
}

async function handleRequest(req, res) {
  if (!authenticate(req, res)) {
    return;
  }

  const urlObject = new URL(req.url, `http://${req.headers.host}`);
  const pathname = urlObject.pathname;

  if (pathname === '/api/health') {
    json(res, 200, { ok: true });
    return;
  }

  if (pathname === '/api/config') {
    json(res, 200, {
      repoKey: config.repoKey,
      areas: {
        firmware: config.firmwarePrefix,
        patch: config.patchPrefix,
      },
    });
    return;
  }

  if (pathname === '/api/list' && req.method === 'GET') {
    await handleList(req, res, urlObject);
    return;
  }

  if (pathname === '/api/upload' && req.method === 'PUT') {
    await handleUpload(req, res, urlObject);
    return;
  }

  if (pathname === '/api/download' && req.method === 'GET') {
    await handleDownload(req, res, urlObject);
    return;
  }

  if (pathname === '/' || pathname.endsWith('.html') || pathname.endsWith('.css') || pathname.endsWith('.js')) {
    await serveStatic(req, res, pathname);
    return;
  }

  json(res, 404, { error: 'Not found.' });
}

http.createServer((req, res) => {
  handleRequest(req, res).catch((error) => {
    json(res, 500, { error: error.message });
  });
}).listen(config.port, () => {
  console.log(`JFrog LAN portal listening on ${config.port}`);
});
