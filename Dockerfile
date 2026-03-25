# ============================================================
# OpenClaw + Ollama — Single Container
# Node 24 required by OpenClaw (https://www.npmjs.com/package/openclaw)
# ============================================================
FROM node:24-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Install Ollama
RUN curl -fsSL https://ollama.com/install.sh | sh

# Install OpenClaw globally (correct package name: openclaw, not @openclaw/cli)
RUN npm install -g openclaw@latest

# Create working directories
RUN mkdir -p /root/.ollama /root/.openclaw/workspace

# Copy entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 18789

ENTRYPOINT ["/entrypoint.sh"]
