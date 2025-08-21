import fs from 'fs';
import crypto from 'crypto';
import path from 'path';

export function ensureDir(p) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

export function loadEnv() {
  const env = {
    PORT: parseInt(process.env.PORT || '3000', 10),
    HEARTBEAT_INTERVAL: parseInt(process.env.HEARTBEAT_INTERVAL || '30', 10),
    REGISTRY_URL: process.env.REGISTRY_URL || '',
    HYDRA_NODE_ID: process.env.HYDRA_NODE_ID || '',
    HYDRA_NODE_NAME: process.env.HYDRA_NODE_NAME || 'hydra-cloud-node',
    HYDRA_SHARED_SECRET: process.env.HYDRA_SHARED_SECRET || '',
    LOG_MAX_BYTES: parseInt(process.env.LOG_MAX_BYTES || (5*1024*1024).toString(), 10),
    LOG_BACKUPS: parseInt(process.env.LOG_BACKUPS || '3', 10),
  };
  return env;
}

export function statePath() {
  return path.resolve('data/state.json');
}

export function loadState() {
  try {
    return JSON.parse(fs.readFileSync(statePath(), 'utf8'));
  } catch {
    return { node_id: null, created_at: null };
  }
}

export function saveState(st) {
  ensureDir(path.dirname(statePath()));
  fs.writeFileSync(statePath(), JSON.stringify(st, null, 2));
}

export function getNodeId(env) {
  const st = loadState();
  if (env.HYDRA_NODE_ID) {
    if (!st.node_id) {
      st.node_id = env.HYDRA_NODE_ID;
      st.created_at = st.created_at || new Date().toISOString();
      saveState(st);
    }
    return env.HYDRA_NODE_ID;
  }
  if (!st.node_id) {
    const id = crypto.randomUUID();
    st.node_id = id;
    st.created_at = new Date().toISOString();
    saveState(st);
    return id;
  }
  return st.node_id;
}

export function rotateLogs(logFile, maxBytes, backups) {
  try {
    const st = fs.statSync(logFile);
    if (st.size < maxBytes) return;
  } catch { return; }

  for (let i = backups - 1; i >= 1; i--) {
    const src = `${logFile}.${i}`;
    const dst = `${logFile}.${i+1}`;
    if (fs.existsSync(src)) {
      fs.renameSync(src, dst);
    }
  }
  if (fs.existsSync(logFile)) {
    fs.renameSync(logFile, `${logFile}.1`);
  }
}

export function sign(payload, secret) {
  if (!secret) return '';
  const h = crypto.createHmac('sha256', secret);
  h.update(payload);
  return h.digest('hex');
}
