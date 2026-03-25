# OpenClaw + Ollama — Single Container for Coolify

A production-ready, single-container deployment of **OpenClaw** (autonomous AI agent) and **Ollama** (LLM runtime), designed for **Coolify** self-hosted PaaS.

Ollama runs locally inside the container as an authentication proxy to **Ollama Cloud**, so no GPU is required on your server — all inference happens remotely.

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                   Coolify Server                     │
│                                                      │
│  ┌────────────────────────────────────────────────┐  │
│  │          Single Docker Container               │  │
│  │                                                │  │
│  │   ┌──────────────┐    ┌──────────────────┐    │  │
│  │   │    Ollama    │    │    OpenClaw      │    │  │
│  │   │  (port 11434)│◄───│  Gateway :18789  │    │  │
│  │   └──────┬───────┘    └──────────────────┘    │  │
│  │          │                     ▲               │  │
│  └──────────┼─────────────────────┼───────────────┘  │
│             │                     │                  │
└─────────────┼─────────────────────┼──────────────────┘
              │ OLLAMA_API_KEY       │ OPENCLAW_GATEWAY_TOKEN
              ▼                     │ (client connects here)
       ┌─────────────┐              │
       │ Ollama Cloud│              │
       │ ollama.com  │         OpenClaw Client
       └─────────────┘         (browser / app)
```

### Why a local Ollama inside the container?

`ollama signin` requires a browser and **does not work in a headless container**.
The correct headless approach is to set `OLLAMA_API_KEY` as an environment variable.
Ollama picks it up automatically when proxying requests to Ollama Cloud — no browser needed.

---

## Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Builds the combined image (Node 24 + Ollama + OpenClaw) |
| `entrypoint.sh` | Starts Ollama, validates env vars, then starts OpenClaw gateway |
| `docker-compose.yml` | Coolify-ready compose file |
| `.env.example` | Template for required environment variables |

---

## Prerequisites

- A [Coolify](https://coolify.io) instance (v4+)
- An [ollama.com](https://ollama.com) account with an **API Key** (not a Device Key)
- A gateway token (generate with `openssl rand -hex 32`)

---

## Quick Start

### 1. Get your Ollama API Key

1. Go to [ollama.com/settings/api-keys](https://ollama.com/settings/api-keys)
2. Create a new **API Key** (not a Device Key — device keys require browser-based `ollama signin` which doesn't work headlessly)
3. Copy the key

### 2. Generate a Gateway Token

```bash
openssl rand -hex 32
```

### 3. Deploy on Coolify

1. In Coolify: **New Resource → Docker Compose**
2. Point it to your Git repo (or paste the `docker-compose.yml` directly)
3. Set environment variables in Coolify's UI:

| Variable | Value |
|----------|-------|
| `OLLAMA_API_KEY` | Your key from ollama.com |
| `OPENCLAW_GATEWAY_TOKEN` | Your generated token |
| `TZ` | e.g. `America/New_York` (optional) |

4. Set the exposed port to `18789`
5. Deploy

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `OLLAMA_API_KEY` | ✅ Yes | API key from ollama.com for cloud model access |
| `OPENCLAW_GATEWAY_TOKEN` | ✅ Yes | Auth token for the OpenClaw gateway |
| `TZ` | ❌ No | Timezone, defaults to `UTC` |

---

## Volumes

| Volume | Mount Path | Purpose |
|--------|-----------|---------|
| `ollama_data` | `/root/.ollama` | Ollama models and config |
| `openclaw_config` | `/root/.openclaw` | OpenClaw config and state |
| `openclaw_workspace` | `/root/.openclaw/workspace` | Agent workspace files |

---

## Authentication Flow

```
OpenClaw → local Ollama (:11434) → Ollama Cloud (ollama.com)
                                         ↑
                              OLLAMA_API_KEY env var
                              (Bearer token in header)
```

1. OpenClaw sends inference requests to local Ollama
2. Local Ollama authenticates to Ollama Cloud using `OLLAMA_API_KEY`
3. Inference runs on Ollama Cloud — no GPU needed on your server

---

## Health Check

The container exposes a health endpoint at `http://localhost:18789/healthz`.

Coolify will automatically monitor this. If the container is unhealthy, Coolify will restart it.

---

## Updating

1. Pull latest changes from your repo
2. In Coolify, click **Redeploy**
3. Coolify will rebuild the image with the latest `openclaw@latest` and `ollama`

To pin versions, edit the `Dockerfile`:
```dockerfile
RUN npm install -g openclaw@2026.3.23-2
```

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| Build fails at `npm install -g openclaw` | Wrong package name | Ensure it's `openclaw`, not `@openclaw/cli` |
| Cloud models not working | Missing API key | Set `OLLAMA_API_KEY` in Coolify env vars |
| Gateway unreachable | Wrong port | Ensure port `18789` is exposed in Coolify |
| Container exits immediately | Missing gateway token | Set `OPENCLAW_GATEWAY_TOKEN` in Coolify env vars |
| Browser/agent crashes | Stale Chrome lock | Entrypoint auto-cleans `SingletonLock` on restart |

---

## Security Considerations

- **Always use HTTPS** — Coolify handles TLS via Let's Encrypt. Never expose the gateway over plain HTTP.
- **Use strong tokens** — Generate `OPENCLAW_GATEWAY_TOKEN` with `openssl rand -hex 32`.
- **Restrict access** — Consider Coolify's built-in IP allowlisting or Cloudflare Access for additional protection.
- **Rotate keys** — Periodically rotate your `OLLAMA_API_KEY` and `OPENCLAW_GATEWAY_TOKEN`.
- **Env vars are visible** — In multi-agent setups, if an agent has shell access it can read env vars. Keep this in mind.

---

## License

This deployment configuration is provided as-is. OpenClaw and Ollama are subject to their respective licenses:

- [OpenClaw License](https://github.com/openclaw/openclaw/blob/main/LICENSE)
- [Ollama License](https://github.com/ollama/ollama/blob/main/LICENSE)
