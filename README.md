# OpenClaw + Ollama — Single Container for Coolify

A production-ready, single-container deployment of **OpenClaw** (autonomous AI agent) and **Ollama** (LLM runtime), designed for **Coolify** self-hosted PaaS.

Ollama runs locally inside the container as an authentication proxy to **Ollama Cloud**, so no GPU is required on your server — all inference happens remotely.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Coolify Server                      │
│                                                      │
│  ┌───────────────────────────────────────────────┐   │
│  │         Single Docker Container                │   │
│  │                                                │   │
│  │   ┌──────────────┐     ┌──────────────────┐   │   │
│  │   │   OpenClaw    │────▶│     Ollama       │   │   │
│  │   │   Gateway     │     │  (local process) │   │   │
│  │   │  :18789       │     │  :11434          │   │   │
│  │   └──────────────┘     └────────┬─────────┘   │   │
│  │                                  │             │   │
│  └──────────────────────────────────┼─────────────┘   │
│                                     │                 │
└─────────────────────────────────────┼─────────────────┘
                                      │ HTTPS + Bearer Token
                                      ▼
                            ┌──────────────────┐
                            │   Ollama Cloud    │
                            │  ollama.com/api   │
                            │  (remote models)  │
                            └──────────────────┘
```

### How It Works

1. **Ollama** starts as a background process inside the container, listening on `localhost:11434`.
2. **Ollama Cloud auth** is handled automatically — the `OLLAMA_API_KEY` environment variable is used by Ollama to authenticate requests to `ollama.com`.
3. **OpenClaw Gateway** starts on port `18789` and connects to the local Ollama instance via its native API (`/api/chat`).
4. When you use a cloud model (e.g. `kimi-k2.5:cloud`), Ollama transparently proxies the request to Ollama Cloud with your API key.
5. **No GPU required** — all model inference runs on Ollama Cloud's infrastructure.

### Authentication Flow

```
User Request
    │
    ▼
OpenClaw Gateway (:18789)
    │  Authenticated via OPENCLAW_GATEWAY_TOKEN
    ▼
Local Ollama (:11434)
    │  No auth needed (localhost)
    ▼
Ollama Cloud (ollama.com/api)
       Authenticated via OLLAMA_API_KEY (Bearer token)
```

---

## Files

| File | Purpose |
|---|---|
| `Dockerfile` | Builds a single image with Ollama + Node.js + OpenClaw |
| `entrypoint.sh` | Starts Ollama, waits for readiness, configures OpenClaw, launches gateway |
| `docker-compose.yml` | Coolify-compatible compose file with volumes and health checks |
| `.env.example` | Template for required environment variables |

---

## Prerequisites

- A **Coolify** instance (v4+)
- An **Ollama Cloud** API key from [ollama.com](https://ollama.com)
- A Git repository to host these files

---

## Quick Start

### 1. Clone and configure

```bash
git clone <your-repo-url>
cd openclaw-ollama
cp .env.example .env
```

Edit `.env` with your values:

```env
OLLAMA_API_KEY=your-ollama-cloud-api-key
OPENCLAW_GATEWAY_TOKEN=your-secure-gateway-token
TZ=UTC
```

### 2. Test locally (optional)

```bash
docker compose up --build
```

OpenClaw will be available at `http://localhost:18789`.

### 3. Deploy on Coolify

1. Push the repo to GitHub/GitLab/Gitea.
2. In Coolify, go to **Add Resource → Docker Compose**.
3. Point it to your repository.
4. Set the following environment variables in the Coolify UI:

   | Variable | Value |
   |---|---|
   | `OLLAMA_API_KEY` | Your API key from [ollama.com](https://ollama.com) |
   | `OPENCLAW_GATEWAY_TOKEN` | A secure random token (e.g. `openssl rand -hex 32`) |
   | `TZ` | Your timezone (e.g. `America/New_York`) |

5. Assign a domain to port `18789`.
6. Click **Deploy**.

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OLLAMA_API_KEY` | ✅ | API key for Ollama Cloud authentication. Get it from your [ollama.com account](https://ollama.com). |
| `OPENCLAW_GATEWAY_TOKEN` | ✅ | Token to secure the OpenClaw gateway API. Use a strong random string. |
| `TZ` | ❌ | Timezone for the container. Defaults to `UTC`. |

---

## Volumes

| Volume | Container Path | Purpose |
|---|---|---|
| `ollama_data` | `/root/.ollama` | Ollama config, cached models, and cloud credentials |
| `openclaw_config` | `/root/.openclaw` | OpenClaw configuration and settings |
| `openclaw_workspace` | `/root/.openclaw/workspace` | OpenClaw agent workspace and generated files |

> **Note:** Volumes ensure your data persists across container restarts and redeployments.

---

## Health Check

The container includes a built-in health check:

```yaml
healthcheck:
  test: ["CMD", "curl", "-sf", "http://127.0.0.1:18789/healthz"]
  interval: 30s
  timeout: 5s
  retries: 5
  start_period: 30s
```

Coolify will automatically monitor container health and restart it if the gateway becomes unresponsive.

---

## Coolify-Specific Notes

- **Port mapping**: Coolify handles external port assignment and TLS termination. You only need to map your domain to port `18789`.
- **Environment variables**: Set them in the Coolify UI, not in the `.env` file (which is for local testing only).
- **Persistent storage**: Coolify manages Docker volumes automatically. Data survives redeployments.
- **No GPU needed**: Since all inference runs on Ollama Cloud, a basic VPS (1–2 vCPU, 1–2 GB RAM) is sufficient.
- **Build context**: Coolify will build the Dockerfile from your repo on deploy. Ensure `entrypoint.sh` is in the repo root alongside the `Dockerfile`.

---

## Troubleshooting

| Issue | Solution |
|---|---|
| Container keeps restarting | Check logs: `docker logs <container>`. Likely missing env vars. |
| "Ollama not ready" in logs | Ollama may need more time to start. Increase `start_period` in health check. |
| Cloud models not working | Verify `OLLAMA_API_KEY` is correct. Test with `curl -H "Authorization: Bearer $KEY" https://ollama.com/api/tags`. |
| OpenClaw gateway unreachable | Ensure Coolify domain is mapped to port `18789`. Check firewall rules. |
| Permission errors on volumes | Ollama image runs as root by default. If using a non-root user, adjust volume permissions. |

---

## Updating

To update OpenClaw or Ollama:

1. **OpenClaw**: Change the version in the `Dockerfile` (`@openclaw/cli@latest` or pin a version like `@openclaw/cli@1.2.3`).
2. **Ollama**: Change the base image tag (`ollama/ollama:latest` or pin like `ollama/ollama:0.5.0`).
3. Push to your repo and redeploy in Coolify.

---

## Security Considerations

- **Always use HTTPS** — Coolify handles TLS via Let's Encrypt. Never expose the gateway over plain HTTP.
- **Use strong tokens** — Generate `OPENCLAW_GATEWAY_TOKEN` with `openssl rand -hex 32`.
- **Restrict access** — Consider Coolify's built-in IP allowlisting or Cloudflare Access for additional protection.
- **Rotate keys** — Periodically rotate your `OLLAMA_API_KEY` and `OPENCLAW_GATEWAY_TOKEN`.

---

## License

This deployment configuration is provided as-is. OpenClaw and Ollama are subject to their respective licenses:

- [OpenClaw License](https://github.com/openclaw/openclaw/blob/main/LICENSE)
- [Ollama License](https://github.com/ollama/ollama/blob/main/LICENSE)
