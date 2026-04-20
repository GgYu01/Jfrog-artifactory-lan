'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { normalizeRelativePath, artifactPath } = require('../lib/paths');

const config = {
  repoKey: 'example-repo-local',
  firmwarePrefix: 'firmware',
  patchPrefix: 'patch',
};

test('normalizeRelativePath removes duplicate slashes and leading separators', () => {
  assert.equal(normalizeRelativePath('/device-a//build-1/'), 'device-a/build-1');
});

test('normalizeRelativePath rejects traversal', () => {
  assert.throws(() => normalizeRelativePath('../escape'), /Path traversal/);
});

test('artifactPath builds firmware target path', () => {
  assert.equal(
    artifactPath('firmware', 'device-a/build-1', 'package.zip', config),
    'example-repo-local/firmware/device-a/build-1/package.zip',
  );
});

test('artifactPath rejects unsupported area', () => {
  assert.throws(() => artifactPath('debug', '', 'x', config), /Unsupported area/);
});

