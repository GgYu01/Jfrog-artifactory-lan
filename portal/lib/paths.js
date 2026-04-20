'use strict';

function sanitizeSegment(value) {
  return String(value || '').replace(/\\/g, '/').trim();
}

function normalizeRelativePath(value) {
  const cleaned = sanitizeSegment(value)
    .split('/')
    .filter(Boolean)
    .map((segment) => {
      if (segment === '.' || segment === '..') {
        throw new Error('Path traversal is not allowed.');
      }
      if (segment.includes('\0')) {
        throw new Error('Invalid path segment.');
      }
      return segment;
    });

  return cleaned.join('/');
}

function areaPrefix(area, config) {
  if (area === 'firmware') {
    return normalizeRelativePath(config.firmwarePrefix);
  }
  if (area === 'patch') {
    return normalizeRelativePath(config.patchPrefix);
  }
  throw new Error(`Unsupported area: ${area}`);
}

function artifactPath(area, relativePath, filename, config) {
  const parts = [
    normalizeRelativePath(config.repoKey),
    areaPrefix(area, config),
  ];

  const normalizedPath = normalizeRelativePath(relativePath || '');
  if (normalizedPath) {
    parts.push(normalizedPath);
  }

  if (filename) {
    parts.push(normalizeRelativePath(filename));
  }

  return parts.filter(Boolean).join('/');
}

module.exports = {
  areaPrefix,
  artifactPath,
  normalizeRelativePath,
};

