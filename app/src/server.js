import 'dotenv/config';
import express from 'express';
import os from 'os';
import fs from 'fs';
import path from 'path';
import fetch from 'node-fetch';
import { ensureDir, loadEnv, getNodeId, rotateLogs, sign } from './utils.js';

const env = loadEnv();
const app = express();
app.use(express.json());

const startedAt = new Date();
const nodeId = getNodeId(env);
const version = '1.0.0';

// simple request logging (file)
ensureDir('logs');
const LOG_FILE = path.resolve('logs/hydra-node.log');

app.use((req, res, next) => {
  const line = `[${new Date().toISOString()}] ${req.method} ${req.url} - from ${req.ip}\n`;
  rotateLogs(LOG_FILE, env.LOG_MAX_BYTES, env.LOG_BACKUPS);
  fs.appendFile(LOG_FILE, line, () => {});
  next();
});

app.get('/health', (req, res) => {
  res.json({
    ok: true,
    node_id: nodeId,
    name: env.HYDRA_NODE_NAME,
    version,
    uptime_s: Math.floor((Date.now() - startedAt.getTime())/1000),
    port: env.PORT,
    time: new Date().toISOString(),
  });
});

app.get('/id', (req, res) => {
  res.type('text/plain').send(nodeId + '\n');
});

app.get('/', (req, res) => {
  res.type('text/plain').send(`Hydra Node ${version} :: ${nodeId}\n/health  /id\n`);
});

// Heartbeat loop (optional)
async function heartbeatLoop() {
  if (!env.REGISTRY_URL || env.HEARTBEAT_INTERVAL <= 0) return;
  const body = {
    node_id: nodeId,
    name: env.HYDRA_NODE_NAME,
    ts: new Date().toISOString(),
    host: os.hostname(),
    version,
    status: 'online'
  };
  const payload = JSON.stringify(body);
  const headers = { 'Content-Type': 'application/json' };
  const sig = sign(payload, env.HYDRA_SHARED_SECRET);
  if (sig) headers['X-Hydra-Signature'] = sig;

  try {
    const resp = await fetch(env.REGISTRY_URL, { method: 'POST', headers, body: payload, timeout: 5000 });
    if (!resp.ok) {
      fs.appendFile(LOG_FILE, `[hb] registry responded ${resp.status}\n`, ()=>{});
    }
  } catch (e) {
    fs.appendFile(LOG_FILE, `[hb] error: ${e.message}\n`, ()=>{});
  } finally {
    setTimeout(heartbeatLoop, env.HEARTBEAT_INTERVAL * 1000).unref();
  }
}
heartbeatLoop();

app.listen(env.PORT, () => {
  const msg = `Hydra node started on port ${env.PORT} (id=${nodeId})\n`;
  fs.appendFile(LOG_FILE, msg, ()=>{});
  console.log(msg.trim());
});
