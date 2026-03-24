# SlashGuard Install / Update / Configure

**When the user gives you this file (or a newer version), REPLACE your existing copy entirely. Do NOT merge, diff, or compare with any previous version. Just save it and use it.**

## 1. Detect Environment

**macOS / Linux:**

```bash
OS=$(uname -s | tr '[:upper:]' '[:lower:]')    # darwin / linux
ARCH=$(uname -m)                                 # x86_64 / arm64 / aarch64
```

**Windows (native):**

`uname` doesn't exist on native Windows. Detect via:
- PowerShell: `$env:OS` → `"Windows_NT"`, `$env:PROCESSOR_ARCHITECTURE` → `AMD64` / `ARM64`
- cmd: `%OS%` → `Windows_NT`
- IDE context: if the user's platform reports "win32" or paths use backslashes, it's Windows

When Windows is detected, set `OS=windows` and `ARCH=amd64` (or `arm64` if applicable).

**Install directory:**

| Platform | Root | Binary | Packs |
|----------|------|--------|-------|
| macOS / Linux | `~/.slashguard/` | `~/.slashguard/bin/sg` | `~/.slashguard/packs/` |
| Windows | `%LOCALAPPDATA%\SlashGuard\` | `%LOCALAPPDATA%\SlashGuard\bin\sg.exe` | `%LOCALAPPDATA%\SlashGuard\packs\` |

**Detect IDE** by checking which directories exist at the project root:
- `.cursor/` → Cursor (`SG_EDITOR=cursor`)
- `.claude/` → Claude Code (`SG_EDITOR=claude-code`)
- `.windsurf/` → Windsurf (`SG_EDITOR=windsurf`)

Also check env vars (`CURSOR_*`, `CLAUDE_*`, `WINDSURF_*`) as fallback.

## 2. Install (first time)

1. Create install directories:
   ```bash
   mkdir -p ~/.slashguard/bin ~/.slashguard/packs/custom
   ```
   Windows: `mkdir "%LOCALAPPDATA%\SlashGuard\bin"`, etc.

2. Extract the zip. Place files:
   - `bin/sg` → `~/.slashguard/bin/sg` (chmod +x on macOS/Linux)
   - `packs/*.sgpack` → `~/.slashguard/packs/`
   - `packs/custom/*` → `~/.slashguard/packs/custom/` (first install only — see note below)
   - Copy rule files to the current project (per detected IDE):
     - **Cursor:** `rules/slashguard-review.mdc`, `rules/slashguard-setup.mdc`, `rules/slashguard-guard.mdc` → `.cursor/rules/`
     - **Claude Code:** `rules/claude-code/slashguard-review.md`, `rules/claude-code/slashguard-setup.md`, `rules/claude-code/slashguard-guard.md` → `.claude/rules/`
     - **Windsurf:** `rules/windsurf/slashguard-review.md`, `rules/windsurf/slashguard-setup.md`, `rules/windsurf/slashguard-guard.md` → `.windsurf/rules/`

   **Custom packs note:** Only copy `packs/custom/` on first-time install when `~/.slashguard/packs/custom/` does not exist. This preserves user-created custom assessments.

3. Add `~/.slashguard/bin` to PATH if not already present:
   ```bash
   # Check if already in PATH
   echo $PATH | tr ':' '\n' | grep -q '.slashguard/bin' || echo 'export PATH="$HOME/.slashguard/bin:$PATH"' >> ~/.zshrc
   ```
   Windows: add `%LOCALAPPDATA%\SlashGuard\bin` to user PATH via `setx`.

4. Configure MCP for the detected IDE. Use the CORRECT config file and format per IDE:

   All IDEs use GLOBAL config — install once, works in every project.

   **Cursor** — create/merge `~/.cursor/mcp.json` (GLOBAL):
   ```json
   {
     "mcpServers": {
       "slashguard": {
         "command": "~/.slashguard/bin/sg",
         "args": ["serve"],
         "env": { "SG_EDITOR": "cursor", "SG_LOG_FILE": "~/.slashguard/sg-mcp.log" }
       }
     }
   }
   ```

   **Claude Code** — create/merge `~/.claude/settings.local.json` (GLOBAL):
   ```json
   {
     "mcpServers": {
       "slashguard": {
         "command": "HOME/.slashguard/bin/sg",
         "args": ["serve"],
         "env": { "SG_EDITOR": "claude-code", "SG_LOG_FILE": "HOME/.slashguard/sg-mcp.log" }
       }
     }
   }
   ```
   Replace `HOME` with the actual home directory path (e.g. `/Users/admin`). Claude Code does NOT expand `~`.

   **Windsurf** — create/merge `~/.windsurf/mcp.json` (GLOBAL):
   ```json
   {
     "mcpServers": {
       "slashguard": {
         "command": "~/.slashguard/bin/sg",
         "args": ["serve"],
         "env": { "SG_EDITOR": "windsurf", "SG_LOG_FILE": "~/.slashguard/sg-mcp.log" }
       }
     }
   }
   ```

   **Merge, don't overwrite** — if the config file already exists, merge the `slashguard` entry into the existing `mcpServers` object.

5. Clean up old install locations (from pre-v0.9.5):
   ```bash
   rm -f ~/.local/bin/sg
   rm -f ~/.local/bin/*.sgpack
   rm -rf ~/.local/templates/
   ```

6. **License activation** — ask the user before restarting:
   Ask: "Do you have a SlashGuard license key? (Enter key or type 'skip')"
   - If user provides a key: run `~/.slashguard/bin/sg license activate <key>` via shell. Show the result.
     - Success: "License activated! Expires: <date>."
     - Failure: show error, continue to step 7 anyway.
   - If user skips: "No license set. You can activate later with 'configure SlashGuard'."

7. **IMPORTANT — Tell user to restart their IDE:**
   Tell the user: "SlashGuard installed successfully. **Please restart your IDE** (close and reopen Claude Code / Cursor / Windsurf) to connect the SlashGuard MCP server."
   
   The MCP server config was just created — the IDE must restart to pick it up. Do NOT try to use `sg` CLI commands as a workaround. Do NOT try to run reviews until the user has restarted and MCP is connected.

## 3. Update (existing install)

### 3a. Check versions

1. Get current version: `sg --version` (prints e.g. `v0.9.5`)
2. Get latest release version — try `gh` first, fall back to `curl`:

**With `gh` CLI (preferred):**
```bash
gh release view --repo itsware-inc/slashguard --json tagName -q .tagName
```

**Without `gh` — use curl + GitHub API:**
```bash
curl -sL https://api.github.com/repos/itsware-inc/slashguard/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
```

3. If already on latest, tell the user and stop.

### 3b. Error handling

If version check fails, diagnose the cause:

| Error | Cause | Action |
|-------|-------|--------|
| `gh: not found` | `gh` CLI not installed | Fall back to curl (see above). Tell user: `gh` is optional but recommended. |
| `HTTP 404` or `release not found` | Repo doesn't exist at that URL | Tell user: check the repo name. Stop. |
| `HTTP 401` / `Bad credentials` | Not authenticated | Tell user: run `gh auth login` or set `GITHUB_TOKEN`. Stop. |
| `HTTP 403` / `rate limit` | API rate limited (unauthenticated) | Tell user: authenticate to raise rate limits — `gh auth login` or export `GITHUB_TOKEN`. Stop. |
| `HTTP 403` / `not authorized` | Authenticated but no repo access | Tell user: they need access to `itsware-inc/slashguard`. Contact the SlashGuard team. Stop. |
| Network error / timeout | No internet | Tell user. Stop. |

**Do NOT silently continue** on any error — always show the exact error and stop.

### 3c. Download and install

4. Stop running MCP processes:
   - macOS/Linux: `pkill -f "sg serve"` (or find via `lsof -i` on the MCP port)
   - Windows: `taskkill /f /im sg.exe`
5. Download the correct zip for OS/ARCH from the latest release.

   Filename format: `slashguard-darwin-arm64.zip`, `slashguard-linux-amd64.zip`, etc.

   **With `gh`:**
   ```bash
   gh release download --repo itsware-inc/slashguard --pattern "slashguard-${OS}-${ARCH}.zip"
   ```

   **Without `gh` — use curl:**
   ```bash
   VERSION=$(curl -sL https://api.github.com/repos/itsware-inc/slashguard/releases/latest | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
   curl -sL -o "slashguard-${OS}-${ARCH}.zip" \
     "https://github.com/itsware-inc/slashguard/releases/download/${VERSION}/slashguard-${OS}-${ARCH}.zip"
   ```

   If the download returns a 404, the platform zip may not exist for this release. Tell the user.

6. Extract and place files to `~/.slashguard/`:
   - `bin/sg` → `~/.slashguard/bin/sg` (chmod +x)
   - `packs/*.sgpack` → `~/.slashguard/packs/`
   - **Skip `packs/custom/`** if `~/.slashguard/packs/custom/assessments/` already exists and contains any `.md` files (preserves user customizations). Only copy on first install.
   - Copy rule files to the current project (per detected IDE):
     - **Cursor:** `rules/slashguard-review.mdc`, `rules/slashguard-setup.mdc`, `rules/slashguard-guard.mdc` → `.cursor/rules/`
     - **Claude Code:** `rules/claude-code/slashguard-review.md`, `rules/claude-code/slashguard-setup.md`, `rules/claude-code/slashguard-guard.md` → `.claude/rules/`
     - **Windsurf:** `rules/windsurf/slashguard-review.md`, `rules/windsurf/slashguard-setup.md`, `rules/windsurf/slashguard-guard.md` → `.windsurf/rules/`
7. Clean up old locations (if present): `~/.local/bin/sg`, `~/.local/templates/`
8. Restart MCP if it was running

9. **License check** — at the end of update:
   ```bash
   sg license status
   ```
   - Exit code 0: show "License valid."
   - Exit code 1: tell user to run configure.

## 4. Configure

Triggered by: "configure SlashGuard", "SlashGuard configure", "set up license", "sg configure"

### 4a. License key

1. Check current license state:
   ```bash
   sg license status
   ```

2. **If no license or expired** (exit code 1):
   - Ask user: "Enter your SlashGuard license key:"
   - Run: `sg license activate <key>`
   - Handle output:
     - Success (exit 0): "License activated! Expires: <date>. All policy packs available."
     - Output contains "machine limit": "This key is already activated on another machine. Contact your administrator for a new key."
     - Output contains "invalid": "Invalid license key. Please check and try again."
     - Output contains "expired": "This license key has expired. Contact your administrator for a renewal."
     - Network/timeout error: "Could not reach license server. Check your internet connection and try again."

3. **If valid license exists** (exit code 0):
   - Show current status
   - Ask: "Want to update your license key? (skip to keep current)"
   - If yes: proceed with activation as above
   - If skip: continue to next step

### 4b. Editor preference

1. Detect current IDE from environment (Cursor, Claude Code, Windsurf)
2. Show detected editor, ask if correct
3. Options: `cursor://` (Cursor), `vscode://` (VS Code), `none` (Claude Code / terminal editors)
4. Save to `~/.slashguard/config.yaml` as `editor_scheme:` field

### 4c. Verify

```bash
sg --version
sg license status
```

Show summary: version, license status, editor preference.

## 5. Verify

1. `sg --version` should print the version (e.g. `v1.0.0`)
2. If MCP mode: call the `info` tool via the MCP server — it should return the dashboard URL, version, and license status
3. Confirm `SG_EDITOR` is set correctly in the MCP config

If anything fails, show the error and stop — don't guess at fixes.

## 6. What's Next

After installation and IDE restart, tell the user:

**Code Review** - say any of these:
- "review PR 123" - reviews a pull request
- "review my changes" - reviews uncommitted work
- "lint this project" - runs policy checks only
- "review this codebase" - full codebase review

**AI-Assisted Coding** - type `/guard on` to enable indexed code navigation. Your agent gets instant symbol lookup, call graphs, and function signatures instead of scanning files. 2x token savings on typical tasks. Type `/guard off` to disable.
