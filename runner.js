import { spawn } from 'child_process';
import path from 'path';
import fs from 'fs';
import { ensureDir, loadEnv, rotateLogs } from './utils.js';

ensureDir('logs');
const env = loadEnv();
const LOG_FILE = path.resolve('logs/hydra-node.log');

let backoff = 1000; // 1s start
const MAX_BACKOFF = 30000; // 30s

function startServer() {
  const node = process.execPath;
  const server = spawn(node, [path.resolve('src/server.js')], {
    stdio: ['ignore', 'pipe', 'pipe'],
    env: process.env
  });

  server.stdout.on('data', (d) => {
    rotateLogs(LOG_FILE, env.LOG_MAX_BYTES, env.LOG_BACKUPS);
    fs.appendFileSync(LOG_FILE, d.toString());
  });
  server.stderr.on('data', (d) => {
    rotateLogs(LOG_FILE, env.LOG_MAX_BYTES, env.LOG_BACKUPS);
    fs.appendFileSync(LOG_FILE, d.toString());
  });

  server.on('exit', (code, sig) => {
    const line = `[runner] server exited code=${code} sig=${sig}\n`;
    fs.appendFileSync(LOG_FILE, line);
    setTimeout(() => {
      backoff = Math.min(backoff * 2, MAX_BACKOFF);
      fs.appendFileSync(LOG_FILE, `[runner] restarting in ${backoff}ms\n`);
      startServer();
    }, backoff).unref();
  });

  server.on('spawn', () => {
    fs.appendFileSync(LOG_FILE, `[runner] server spawned pid=${server.pid}\n`);
    backoff = 1000; // reset on success
  });

  function shutdown() {
    try { server.kill('SIGTERM'); } catch {}
    process.exit(0);
  }
  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

startServer();
