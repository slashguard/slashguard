# SlashGuard — Usage Guide

## Chat Prompts

SlashGuard is controlled through natural language. Your AI agent translates prompts into MCP tool calls.

### Lint Only (fast, no LLM cost)

| Prompt | What Happens |
|--------|-------------|
| `lint my changes` | Lint uncommitted + unpushed changes |
| `lint PR 834` | Lint a specific PR diff |
| `lint go_server changes` | Lint changes in a specific repo (multi-repo workspace) |
| `full lint` | Lint the entire codebase |

### Full Review (lint + AI)

| Prompt | What Happens |
|--------|-------------|
| `review PR 834` | Lint + AI review of PR diff |
| `review my changes` | Lint + AI review of working tree + unpushed commits |
| `review working changes in go_server` | Full review of a specific repo |
| `review branch vs dev` | Compare current branch against dev |

### Multi-Repo Workspaces

If your workspace has multiple git repos, the agent will ask which one to review. You can also specify it directly:

```
review go_server PR 834
lint changes in itsware-web-app
```

## Review Workflow

### 1. Session Creation

The agent calls `review_start` which:
- Indexes the repo (cached locally -- fast on subsequent runs)
- Computes the diff scope (which files/functions changed)
- Returns: session ID, chunk count, function count, rules count

### 2. Lint Phase

The agent calls `review_scan` in batches until all rules are checked.

- Checks are deterministic policy rules that run against your indexed codebase
- Each rule runs in milliseconds
- Findings stream to the dashboard in real time
- **Gate rules**: critical violations that block AI review

### 3. AI Review Phase

The orchestrator agent spawns subagents (one per chunk):

1. Each subagent receives function source code + pre-fetched callee implementations
2. Subagent can call `look` for additional symbol lookups and to trace callers/callees
3. Subagent evaluates each function against AI rules and submits PASS/FAIL verdicts

**Note:** AI review quality depends on your IDE's current model. Different models produce different results. Usage of `look` for context (callees, callers) also varies by model capability.

### 4. Results

After completion:

- **Dashboard**: http://localhost:19880/review/{session_id} -- live findings with syntax highlighting
- **Export**: Click "Download Report" in the dashboard for a JSON report
- **Artifacts**: Two files saved to `.slashguard/reviews/` in the repo:
  - `{session_id}-lint.json` -- machine-readable lint results
  - `{session_id}-lint.md` -- human-readable markdown report

The agent also shows artifact paths in chat when lint completes.

## Dashboard

The dashboard streams findings in real time via Server-Sent Events:
- **Lint tab**: all lint findings grouped by rule, with code snippets
- **AI Review tab**: per-function AI verdicts with explanations
- **Export**: "Download Report" button exports JSON with all findings
- **Fix with AI**: copies a structured prompt to clipboard for fixing findings

## Claude Code

SlashGuard works with Claude Code (Anthropic's CLI agent). Lint findings display directly in your terminal with `path:line` references, and the dashboard opens automatically in your browser.

Full PR reviews with AI also work. Claude Code reviews each chunk sequentially (no parallel subagents).

SlashGuard also works on Windows via WSL2 (Windows Subsystem for Linux).

**Note:** Claude Code asks for permission the first time each SlashGuard tool is called (`review_start`, `review_scan`, `review_assess`, `look`, etc.). Always pick **option 2** ("Yes, and don't ask again") to auto-approve for the project. After one full review cycle all tools are approved.

## CLI Usage

SlashGuard can also be used from the command line:

```bash
# One-shot index
sg index --repo /path/to/project

# Index with database schema
sg index --repo /path/to/project --target-db "postgres://user:pass@localhost:5432/db"

# Environment check
sg check --repo /path/to/project

# Start MCP server (editors do this automatically)
sg serve
```

## MCP Tools Reference

| Tool | Purpose | Key Parameters |
|------|---------|---------------|
| `review_start` | Start a review session | `mode` (pr/working/diff/full), `repo`, `ref` |
| `review_scan` | Run lint rules in batches | `session_id`, `batch_size` |
| `review_assess` | Claim a chunk for AI review | `session_id` |
| `look` | Look up symbol source, trace callers/callees | `session_id`, `worker_id`, `symbol` |
| `review_report` | Submit AI findings | `session_id`, `worker_id`, `findings` |
| `info` | Server status + dashboard URL | -- |

## Worktrees and PR Reviews

For PR reviews, SlashGuard:
1. Fetches the PR branch (`git fetch origin pull/N/head:pr-N`)
2. Indexes the repo on demand (cached for speed)
3. Computes the diff against the base branch
4. Resolves which functions overlap with changed lines
5. Only those functions are reviewed (scoped review)

This means the review focuses on what actually changed, not the entire codebase.