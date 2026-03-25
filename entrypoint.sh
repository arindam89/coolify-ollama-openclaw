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

# Check for Ollama Cloud API key
if [ -n "$OLLAMA_API_KEY" ]; then
  echo "Ollama Cloud: API key configured"
else
  echo "WARNING: No OLLAMA_API_KEY set — cloud models won't work"
fi

# Start OpenClaw gateway
exec openclaw gateway --port 18789 --bind lan --allow-unconfigured --token "$OPENCLAW_GATEWAY_TOKEN"