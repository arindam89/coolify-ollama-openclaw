#!/bin/bash
set -e

# Start Ollama in the background
ollama serve &
OLLAMA_PID=$!

# Wait for Ollama to be ready
echo "Waiting for Ollama..."
until curl -sf http://127.0.0.1:11434/api/tags > /dev/null 2>&1; do
  sleep 1
done
echo "Ollama is ready."

# Sign in to Ollama Cloud (uses OLLAMA_API_KEY env var)
if [ -n "$OLLAMA_API_KEY" ]; then
  echo "Signing in to Ollama Cloud..."
  # Ollama uses OLLAMA_API_KEY automatically for cloud model requests
  export OLLAMA_API_KEY="$OLLAMA_API_KEY"
fi

# Run OpenClaw onboarding non-interactively if not already configured
if [ ! -f /root/.openclaw/config.json ]; then
  openclaw onboard --non-interactive \
    --auth-choice ollama \
    --accept-risk
fi

# Start OpenClaw gateway
exec node $(which openclaw) gateway \
  --bind lan \
  --port 18789