# SlashGuard vX.Y.Z

**Release date:** YYYY-MM-DD

## Two Modes

### /review - Code Review

800+ policy checks + AI assessment across Go, Python, C#, TypeScript, Vue, SQL. All languages in parallel.

Tell your agent:
- **"review PR 123"** - reviews a pull request
- **"review my changes"** - reviews uncommitted work
- **"lint this project"** - policy checks only
- **"review this codebase"** - full codebase review

For best AI assessment quality, use Claude Opus.

### /guard on - AI-Assisted Coding

Your agent gets indexed access to your codebase - instant symbol lookup, call graphs, function signatures. No more scanning hundreds of files.

| | SlashGuard OFF | SlashGuard ON |
|---|---|---|
| "how does the export middleware work?" | Scanned 47 files | Indexed lookup, 2 calls |
| "what other middlewares do we have?" | Scanned 15 more files | Already indexed |
| **Token budget used** | **24.7K** | **11.7K** |

## Install

Tell your AI agent:
> Read https://github.com/itsware-inc/slashguard and install SlashGuard

Or pick the setup skill for your editor: [Cursor](https://raw.githubusercontent.com/itsware-inc/slashguard/main/setup/slashguard-setup.mdc) | [Claude Code](https://raw.githubusercontent.com/itsware-inc/slashguard/main/setup/slashguard-setup-claude.md) | [Windsurf](https://raw.githubusercontent.com/itsware-inc/slashguard/main/setup/slashguard-setup-windsurf.md)

Activate your license: `sg license activate YOUR_KEY`

[Full install guide](INSTALL.md) | [Usage guide](USAGE.md)

## GitHub Actions CI

Automated code review on every pull request — no IDE needed.

1. Copy [workflow template](docs/workflow-template.yml) to `.github/workflows/slashguard-review.yml`
2. Set 3 secrets: `ANTHROPIC_API_KEY`, `SG_LICENSE_DAT`, `SG_REPO_TOKEN`
3. Open a PR — SlashGuard reviews automatically

See [CI Setup Guide](docs/ci-setup.md) for full instructions.

## Downloads

| Platform | File |
|----------|------|
| macOS (Apple Silicon) | `slashguard-darwin-arm64.zip` |
| macOS (Intel) | `slashguard-darwin-amd64.zip` |
| Linux (x64) | `slashguard-linux-amd64.zip` |
| Linux (ARM64) | `slashguard-linux-arm64.zip` |
| Windows (x64) | `slashguard-windows-amd64.zip` |

## What's New

- ITEM_1
- ITEM_2
- ITEM_3

## Policy Packs (820 total)

| Language | Policies |
|----------|----------|
| Go | 102 |
| Python | 228 |
| C# | 276 |
| TypeScript / React | 62 |
| Vue | 85 |
| SQL / PL/pgSQL | 33 |
| Accessibility | 26 |

## Requirements

- macOS (Intel or Apple Silicon), Linux (x64 or ARM64), Windows (x64), or WSL2
- Cursor, Claude Code, or Windsurf
- License key (30-day trial available)
