# agent-dev-base-devcontainer

Devcontainer template for AI agent development using the [agent-dev-base](https://github.com/DataViking-Tech/agent-dev-base) image.

## Quick Start

1. **Use this template** — click "Use this template" on GitHub, or clone directly
2. **Open in VS Code** — VS Code will detect `.devcontainer/devcontainer.json` and offer to reopen in container
3. **Start building** — `gc`, `bd`, `claude`, `codex`, `amp` are all available

## What you get

- [Gas City](https://github.com/gastownhall/gascity) (`gc`) for multi-agent orchestration
- [Beads](https://github.com/gastownhall/beads) (`bd`) for work tracking
- AI CLIs: Claude, Codex, Amp
- Docker-in-Docker for container workflows
- Claude config mounted from host (`~/.claude`)

## Customizing

Add language runtimes or project-specific tools in `.devcontainer/devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": { "version": "20" },
    "ghcr.io/devcontainers/features/python:1": { "version": "3.12" }
  }
}
```

Or build a downstream Dockerfile:

```json
{
  "build": {
    "dockerfile": "Dockerfile"
  }
}
```
