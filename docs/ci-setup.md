# SlashGuard CI/CD Setup Guide

Automated code review on every pull request using SlashGuard + Claude Code Action.

## How It Works

When a PR is opened, GitHub Actions:
1. Downloads the SlashGuard binary and rule packs from the release
2. Starts SlashGuard as an MCP server
3. Claude Code Action connects to SlashGuard via MCP
4. Claude runs the lint checks (800+ rules) then AI assessments
5. Findings are posted as inline PR comments with a summary verdict

No Docker needed. The `sg` binary runs natively on `ubuntu-latest`. The review takes 2-4 minutes depending on diff size.

## Prerequisites

- **Anthropic API key** — for the Claude Code Action ([get one here](https://console.anthropic.com/))
- **SlashGuard license** — a CI-policy license with no machine fingerprint binding
- **GitHub repo access** — the workflow needs read access to `slashguard/slashguard` releases

## Setup (3 steps)

### 1. Set GitHub secrets

Your repo needs three secrets:

| Secret | What | How to get it |
|--------|------|---------------|
| `ANTHROPIC_API_KEY` | Anthropic API key | [console.anthropic.com](https://console.anthropic.com/) |
| `SG_LICENSE_DAT` | Base64-encoded SlashGuard CI license | Provided by SlashGuard — org-bound to your GitHub org |
| `SG_REPO_TOKEN` | GitHub PAT with read access to `slashguard/slashguard` | [github.com/settings/tokens](https://github.com/settings/tokens) |

> **CI licenses are org-bound.** Each license is tied to a specific GitHub organization via `GITHUB_REPOSITORY_OWNER`. A license activated for `acme-corp` will only work in repos under `acme-corp/*`. Contact SlashGuard for your org's license.

Set them via CLI:
```bash
gh secret set ANTHROPIC_API_KEY --repo <your-org>/<your-repo>
gh secret set SG_LICENSE_DAT --repo <your-org>/<your-repo>
gh secret set SG_REPO_TOKEN --repo <your-org>/<your-repo>
```

### 2. Add the workflow file

Copy `docs/workflow-template.yml` to `.github/workflows/slashguard-review.yml` in your repo.

Or create it manually — the template is self-contained and uses GitHub Actions expressions for all paths (no hardcoded values).

### 3. Open a PR

Push any branch and open a PR. The workflow triggers automatically on `opened`, `synchronize`, and `reopened` events. Claude will post inline comments and a summary review.

## What the workflow does

```
PR opened
  → actions/checkout (full history)
  → git fetch origin <base branch>
  → Download sg binary + rule packs from release
  → Decode license.dat from secret
  → Write MCP config to /tmp
  → Claude Code Action starts
    → sg serve --repo <workspace> (MCP server)
    → review_start (mode=diff, HEAD vs base)
    → review_scan (lint checks in batches)
    → review_assess + review_report (AI assessment)
    → Post inline comments + summary verdict
```

## Configuration

### Changing the SlashGuard version

The workflow pins to a specific release tag (e.g., `v1.0.1`). To update, change the version in both `gh release download` steps.

### Base branch

The workflow auto-detects the PR's base branch via `${{ github.event.pull_request.base.ref }}`. The `prompt` passes it as `base="origin/<base>"` to `review_start`. If your repo uses `dev` as the default branch, this works automatically.

### Blocking vs informational

The workflow runs with `continue-on-error: true` so it shows as informational, not blocking. To make it a required check, remove that line and add it as a required status check in branch protection.

### show_full_output

Set to `"true"` in the workflow to see Claude's full execution log in the Actions output. Set to `"false"` for production (hides output for security).

## Handling Findings (Suppression Workflow)

When SlashGuard flags something in your PR, each finding comment includes a ready-to-paste YAML block. To suppress a finding:

1. Copy the YAML block from the PR comment
2. Add it to `.sgsuppress.yaml` at the repo root (create the file if needed)
3. Fill in `reason` and `by` fields
4. Push — CI re-runs automatically, suppressed findings disappear

### Gate → Suppress → Re-run → AI Review

```
PR opened / updated
  → CI triggers
  → review_scan: 2 gate violations (errors), 3 warnings
  → Claude posts CHANGES_REQUESTED + error comments with suppress_yaml blocks
  → Job stops — no AI assessment

Developer triages:
  → Copies suppress_yaml blocks from PR comments
  → Creates .sgsuppress.yaml, fills in reason + by
  → Pushes to PR branch

CI re-triggers (synchronize event)
  → review_scan: same rules, but 2 findings now match .sgsuppress.yaml
  → 0 active gate violations, 3 active warnings
  → Gate passes → AI assessment runs
  → Claude posts APPROVED (or COMMENT if AI finds issues)
  → Summary: 0 errors, 3 warnings, 2 suppressed
```

**Key points:**
- Only gate violations (errors) block AI review. Warnings never block.
- Suppressed findings don't count toward gate violations.
- When all gate violations are suppressed, AI assessment proceeds automatically on the next push.
- The `.sgsuppress.yaml` file is version-controlled — suppressions are visible in PRs and auditable.

### Suppression expiry

Tier 3 suppressions (with `fingerprint`) auto-expire when the targeted code changes. If you suppress a SQL injection finding and later modify that function, the suppression stops matching and the finding comes back. This is intentional — changed code deserves fresh review.

Stale suppressions appear as warnings in the summary:
```
⚠️ Stale suppression: SQL_INJECTION_CONCAT in Validate
   Fingerprint no longer matches. Remove from .sgsuppress.yaml or update.
```

### Protecting .sgsuppress.yaml

Consider adding a CODEOWNERS entry so suppression changes require review:
```
.sgsuppress.yaml  @security-team
```

For more details on the suppression system (4 tiers, inline comments, statuses), see `docs/suppression-reference.md` and `docs/triage-guide.md`.

## Future: Check Run Buttons (Phase 2)

> Not yet implemented. This section documents the planned design.

GitHub Check Runs support action buttons, but the `identifier` field has a **20-character limit**. To work around this, findings are stored in an artifact and referenced by short ID.

**Planned design:**

```
Check step generates findings.json artifact:
  { "f001": { "rule": "...", "target": "...", "fingerprint": "...", "source": "..." } }

Each Check Run has 4 buttons:
  "False Positive" → identifier: "s:f001:fp" (12 chars, fits in 20 limit)
  "Won't Fix"      → identifier: "s:f001:wf"
  "Test Code"      → identifier: "s:f001:tc"
  "Accepted"       → identifier: "s:f001:ac"

Suppress Action (triggered on check_run.requested_action):
  1. Downloads findings.json artifact
  2. Looks up f001 → full rule, target, fingerprint
  3. Appends to .sgsuppress.yaml
  4. Commits to PR branch
  5. Push triggers re-run → finding suppressed → green
```

## Deferred Items

These are planned but not yet implemented:

1. **PR comment dismissal commands** — reply to a finding comment with `@slashguard dismiss false_positive - validated upstream` or `@slashguard dismiss wont_fix - accepted risk`. The workflow would parse the comment, map it back to the finding, append to `.sgsuppress.yaml`, and push.

2. **Azure DevOps parity** — same suppression model with PR comment commands (`/suppress f001 false_positive "reason"`), optional extension/tab with triage buttons.

3. **Per-PR suppressions** — a `.sgsuppress.pr.yaml` file for temporary suppressions that should not land on the default branch.

4. **Audit command** — `sg audit-suppressions` or `mcp__slashguard__triage(action: "audit")` to report stale and unused suppressions repo-wide.

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| "No trigger found, skipping" | Wrong action version or missing `prompt` | Use `@v1`, pass `prompt` (not `direct_prompt`) |
| "Unable to get OIDC token" | Missing `id-token: write` permission | Add it to workflow `permissions` |
| Binary download fails (404) | Wrong release tag or private repo | Check `SG_REPO_TOKEN` has read access |
| "LICENSE_REQUIRED" from MCP | License not decoded properly | Verify: `echo "$SG_LICENSE_DAT" \| base64 -d \| python3 -m json.tool` |
| Findings on wrong lines | Shallow checkout | Must use `fetch-depth: 0` |
| No review posted | MCP server crash or stdout pollution | Check Actions log, enable `show_full_output` |
| Claude doesn't call SlashGuard tools | Tools not in `--allowedTools` | Ensure all `mcp__slashguard__*` tools are listed |

## Reference


- **Claude Code Action docs:** [github.com/anthropics/claude-code-action](https://github.com/anthropics/claude-code-action)
- **Workflow template:** `docs/workflow-template.yml` in this repo
