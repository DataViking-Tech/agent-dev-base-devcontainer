#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Agent Dev Base — postStartCommand
#
# Runs on every container start. Responsible for:
#   1. Fixing ownership on persisted volume mounts
#   2. Seeding Claude config
#   3. First-run city initialization (gc init) if no city exists AND at least
#      one LLM CLI is authenticated
# =============================================================================

# ---------------------------------------------------------------------------
# 1. Fix ownership on persisted volume mounts
# ---------------------------------------------------------------------------
sudo chown -R devuser:devuser \
  /home/devuser/.claude \
  /home/devuser/.claude-config \
  /home/devuser/.codex \
  /home/devuser/.config/amp 2>/dev/null || true

# ---------------------------------------------------------------------------
# 2. Claude config persistence
# ---------------------------------------------------------------------------
# Seed Claude config with an empty JSON object if missing/empty.
if [ ! -s /home/devuser/.claude-config/claude.json ]; then
  echo '{}' > /home/devuser/.claude-config/claude.json
fi

# Symlink ~/.claude.json to the persisted file in the stash volume.
if [ ! -L /home/devuser/.claude.json ]; then
  ln -sf /home/devuser/.claude-config/claude.json /home/devuser/.claude.json
fi

# ---------------------------------------------------------------------------
# 3. First-run city initialization
# ---------------------------------------------------------------------------
# Detect whether this workspace already contains a gc city. We look for the
# canonical marker files: city.toml at the workspace root or a .gc/ directory.
# If neither exists, and at least one LLM CLI is authenticated, run `gc init`
# to scaffold a fresh city.
#
# This is intentionally conservative:
#   - We NEVER run gc init if a city already exists (no clobbering)
#   - We NEVER run gc init without an authenticated LLM CLI (gc needs a
#     provider to make LLM calls during init)
#   - Users can always run gc init manually if this auto-detection skips
# ---------------------------------------------------------------------------

WORKSPACE_DIR="${PWD}"

has_city() {
  [ -f "${WORKSPACE_DIR}/city.toml" ] || [ -d "${WORKSPACE_DIR}/.gc" ]
}

# Check whether at least one LLM CLI is authenticated.
# Each CLI exposes auth state differently — we probe each one's known-safe
# status commands and treat non-zero exit or absence as "not authed".
llm_authed() {
  # Claude Code — config file has a non-empty oauthAccount or similar.
  # The claude binary exits 0 on `claude --version` regardless of auth, so we
  # inspect the config file directly.
  if [ -s /home/devuser/.claude-config/claude.json ]; then
    if jq -e '.oauthAccount // .accounts // .apiKey // empty' \
        /home/devuser/.claude-config/claude.json >/dev/null 2>&1; then
      return 0
    fi
  fi

  # Codex — ~/.codex/auth.json or similar marker
  if [ -f /home/devuser/.codex/auth.json ] \
     || [ -f /home/devuser/.codex/config.json ]; then
    return 0
  fi

  # Amp — ~/.config/amp/config.json or similar
  if [ -f /home/devuser/.config/amp/config.json ] \
     || [ -f /home/devuser/.config/amp/auth.json ]; then
    return 0
  fi

  return 1
}

maybe_init_city() {
  if has_city; then
    return 0
  fi

  if ! llm_authed; then
    echo ""
    echo "──────────────────────────────────────────────────────────────────"
    echo "  No gc city detected and no LLM CLI appears to be authenticated."
    echo ""
    echo "  To initialize a city, first authenticate one of:"
    echo "    claude                  # then /login"
    echo "    codex login"
    echo "    amp login"
    echo ""
    echo "  Then run: gc init"
    echo "──────────────────────────────────────────────────────────────────"
    echo ""
    return 0
  fi

  echo ""
  echo "──────────────────────────────────────────────────────────────────"
  echo "  First run detected — initializing gc city in:"
  echo "    ${WORKSPACE_DIR}"
  echo "──────────────────────────────────────────────────────────────────"
  echo ""

  if ! gc init; then
    echo ""
    echo "  gc init failed. Check the error above and run 'gc init' manually."
    echo ""
    return 1
  fi

  echo ""
  echo "  City initialized. Commit the new files to your repo when ready."
  echo ""
}

maybe_init_city
