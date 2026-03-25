#!/bin/bash
set -e

# Clean up any stale Chrome lock files from previous runs
find /root/.openclaw -name SingletonLock -delete 2>/dev/null || true

# Start Ollama in the background
ollama serve &

# Wait for Ollama to be ready
echo "[entrypoint] Waiting for Ollama to start..."
until curl -sf http://127.0.0.1:11434/api/tags > /dev/null 2>&1; do
  sleep 1
done
echo "[entrypoint] Ollama is ready."

# Validate Ollama Cloud API key
if [ -n "$OLLAMA_API_KEY" ]; then
  echo "[entrypoint] OLLAMA_API_KEY is set — Ollama Cloud models will be available."
else
  echo "[entrypoint] WARNING: OLLAMA_API_KEY is not set. Cloud models will not work."
fi

# Validate OpenClaw gateway token
if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
  echo "[entrypoint] ERROR: OPENCLAW_GATEWAY_TOKEN is required but not set. Exiting."
  exit 1
fi

echo "[entrypoint] Starting OpenClaw gateway on port 18789..."
exec openclaw gateway --port 18789 --bind 0.0.0.0 --token "$OPENCLAW_GATEWAY_TOKEN"
