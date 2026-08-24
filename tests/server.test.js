const test = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { spawn } = require('node:child_process');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');

function request(port, pathName) {
  return new Promise((resolve, reject) => {
    http.get(`http://127.0.0.1:${port}${pathName}`, (res) => {
      let body = '';
      res.on('data', (chunk) => { body += chunk; });
      res.on('end', () => resolve({ status: res.statusCode, body: JSON.parse(body) }));
    }).on('error', reject);
  });
}

async function waitForHealth(port) {
  const deadline = Date.now() + 5000;
  while (Date.now() < deadline) {
    try {
      await request(port, '/health');
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  throw new Error(`service on port ${port} did not become healthy`);
}

test('health endpoint is healthy', async () => {
  const server = spawn(process.execPath, ['app/server.js'], {
    cwd: ROOT,
    env: { ...process.env, PORT: '3210', APP_VERSION: 'test' },
    stdio: 'ignore'
  });
  try {
    await waitForHealth(3210);
    const result = await request(3210, '/health');
    assert.equal(result.status, 200);
    assert.equal(result.body.status, 'ok');
    assert.equal(result.body.version, 'test');
  } finally {
    server.kill('SIGTERM');
  }
});

test('readiness endpoint is healthy', async () => {
  const server = spawn(process.execPath, ['app/server.js'], {
    cwd: ROOT,
    env: { ...process.env, PORT: '3211', APP_VERSION: 'test' },
    stdio: 'ignore'
  });
  try {
    await waitForHealth(3211);
    const result = await request(3211, '/ready');
    assert.equal(result.status, 200);
    assert.equal(result.body.status, 'ready');
  } finally {
    server.kill('SIGTERM');
  }
});
