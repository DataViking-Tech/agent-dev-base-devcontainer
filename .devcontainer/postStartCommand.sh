#!/usr/bin/env bash
set -euo pipefail

# Fix ownership on persisted volume mounts (may not all exist; ignore failures).
sudo chown -R devuser:devuser \
  /home/devuser/.claude \
  /home/devuser/.claude-config \
  /home/devuser/.codex \
  /home/devuser/.config/amp 2>/dev/null || true

# Seed Claude config with an empty JSON object if missing/empty.
if [ ! -s /home/devuser/.claude-config/claude.json ]; then
  echo '{}' > /home/devuser/.claude-config/claude.json
fi

# Symlink ~/.claude.json to the persisted file in the stash volume.
if [ ! -L /home/devuser/.claude.json ]; then
  ln -sf /home/devuser/.claude-config/claude.json /home/devuser/.claude.json
fi
