#!/bin/bash
set -e

# Start Ollama in the background
ollama serve &

# Wait for Ollama to be ready
echo "Waiting for Ollama..."
until curl -sf http://127.0.0.1:11434/api/tags > /dev/null 2>&1; do
  sleep 1
done
echo "Ollama is ready!"

# Check if already signed in to Ollama Cloud
if ollama list 2>&1 | grep -q "cloud"; then
  echo "Ollama Cloud: Already signed in (credentials in volume)"
else
  echo "=============================================="
  echo "  OLLAMA CLOUD NOT CONFIGURED"
  echo "  Run this once to sign in:"
  echo ""
  echo "  docker exec -it <container> ollama signin"
  echo "=============================================="
fi

# Start OpenClaw gateway
exec openclaw gateway --port 18789 --bind 0.0.0.0 --token "$OPENCLAW_GATEWAY_TOKEN"