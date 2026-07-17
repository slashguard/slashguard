<p align="center">
  <img src="assets/logo.svg" alt="SlashGuard" width="400">
</p>

<p align="center">
  AI-powered code review and developer intelligence for your IDE.
</p>

## What It Does

### /review - Code Review

800+ policy checks across Go, Python, C#, TypeScript, Vue, and SQL. AI assessments evaluate architecture, security, and error handling. All languages reviewed in parallel.

Tell your agent:
- **"review PR 123"** - reviews a pull request
- **"review my changes"** - reviews uncommitted work
- **"lint this project"** - runs policy checks only
- **"review this codebase"** - full codebase review

For best AI assessment quality, use Claude Opus (higher reasoning effort).

See the [Usage Guide](USAGE.md) for all commands and options.

### /guard - AI-Assisted Coding

Enable SlashGuard for your session to get faster code navigation and lower token usage. Your agent gets indexed access to your entire codebase - instant symbol lookup, call graphs, and function signatures instead of scanning files.

```
/guard on     -> agent confirms: "SlashGuard is active"
/guard off    -> back to normal
```

**Real example - understanding a codebase:**

| | SlashGuard OFF | SlashGuard ON |
|---|---|---|
| "how does the export middleware work?" | Scanned 47 files | Indexed lookup, 2 calls |
| "what other middlewares do we have?" | Scanned 15 more files | Already indexed |
| **Token budget used** | **24.7K** | **11.7K** |

2x token reduction even in a simple example. On large codebases the difference is bigger.

## Quick Start

**Option 1** - Tell your AI agent:
> Read https://github.com/slashguard/slashguard and install SlashGuard

**Option 2** - Point your agent to the setup skill for your editor:

| Editor | Setup Skill |
|--------|-------------|
| Cursor | [slashguard-setup.mdc](https://raw.githubusercontent.com/slashguard/slashguard/main/setup/slashguard-setup.mdc) |
| Claude Code | [slashguard-setup-claude.md](https://raw.githubusercontent.com/slashguard/slashguard/main/setup/slashguard-setup-claude.md) |
| Windsurf | [slashguard-setup-windsurf.md](https://raw.githubusercontent.com/slashguard/slashguard/main/setup/slashguard-setup-windsurf.md) |

Copy the link, paste it to your agent, and say **"read this and install SlashGuard"**.

**Option 3** - [Manual install](INSTALL.md)

## Supported Languages

All languages analyzed in parallel during review.

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

## License

Proprietary. See [LICENSE](LICENSE).

## Links

- [Install Guide](INSTALL.md)
- [Usage Guide](USAGE.md)
- [ItsWare](https://itsware.com)
