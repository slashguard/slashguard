# SlashGuard - Installation

> **For AI agents:** Detect your platform with `uname -s` and `uname -m` (macOS/Linux). On native Windows, `uname` is not available - detect via `$env:OS` (PowerShell) or IDE platform context. Skip manual platform selection - use the table below to determine the correct binary automatically.

SlashGuard is an MCP server. Install the binary, add it to your editor's MCP config, and copy the review rule.

## Quick Setup (Recommended)

Point your AI agent to the setup skill for your editor:

| Editor | Setup Skill |
|--------|-------------|
| Cursor (.mdc rule) | `https://raw.githubusercontent.com/itsware-inc/slashguard/main/setup/slashguard-setup.mdc` |
| Claude Code (.md skill) | `https://raw.githubusercontent.com/itsware-inc/slashguard/main/setup/slashguard-setup-claude.md` |
| Windsurf (.md rule) | `https://raw.githubusercontent.com/itsware-inc/slashguard/main/setup/slashguard-setup-windsurf.md` |

Copy the link for your editor, paste it to your agent, and say **"read this skill and install SlashGuard"**.

The skill handles everything: platform detection, binary download, MCP configuration, rule installation, license activation, and verification.

The manual steps below are for reference or if you prefer to install by hand.

---

## 1. Install the Binary

### macOS

```bash
mkdir -p ~/.slashguard/bin
# Apple Silicon (M1/M2/M3/M4):
mv ~/Downloads/sg-darwin-arm64 ~/.slashguard/bin/sg
# Intel:
# mv ~/Downloads/sg-darwin-amd64 ~/.slashguard/bin/sg

chmod +x ~/.slashguard/bin/sg
xattr -d com.apple.quarantine ~/.slashguard/bin/sg
```

### Windows

Download `sg-windows-amd64.exe` and rename to `sg.exe`. Place it in one of:

- `%LOCALAPPDATA%\SlashGuard\sg.exe` (recommended, e.g. `C:\Users\YOU\AppData\Local\SlashGuard\sg.exe`)
- `C:\Users\YOU\.local\bin\sg.exe`

No admin rights required - both locations are within the user's profile.

### Linux / WSL2

```bash
mkdir -p ~/.slashguard/bin
# x86_64:
mv ~/Downloads/sg-linux-amd64 ~/.slashguard/bin/sg
# ARM64 (e.g. WSL2 on Apple Silicon VM):
# mv ~/Downloads/sg-linux-arm64 ~/.slashguard/bin/sg
chmod +x ~/.slashguard/bin/sg
```

### Which binary?

| System | Download |
|--------|----------|
| Mac M1/M2/M3/M4 | `sg-darwin-arm64` |
| Mac Intel | `sg-darwin-amd64` |
| Windows | `sg-windows-amd64.exe` |
| Linux x86_64 | `sg-linux-amd64` |
| Linux ARM64 / WSL2 on Apple Silicon | `sg-linux-arm64` |

**Not sure which Mac?** Apple menu → About This Mac. "Apple M1/M2/M3/M4" → arm64.

---

## 2. Install Policy Packs

Copy the `.sgpack` files from the release zip to `~/.slashguard/packs/`:

```bash
mkdir -p ~/.slashguard/packs
cp path/to/release/*.sgpack ~/.slashguard/packs/
```

The packs contain all deterministic checks and AI assessment criteria.

**Windows:**

Copy the `.sgpack` files to `%LOCALAPPDATA%\SlashGuard\packs\`.

---

## 3. Add MCP Config (per editor)

### Cursor

Edit `~/.cursor/mcp.json` (global) or `.cursor/mcp.json` (per-workspace):

```json
{
  "mcpServers": {
    "slashguard": {
      "command": "/Users/YOU/.slashguard/bin/sg",
      "args": ["serve"],
      "env": {
        "SG_LOG_FILE": "/Users/YOU/.slashguard/sg-mcp.log",
        "SG_EDITOR": "cursor"
      }
    }
  }
}
```

### Windsurf

Edit `~/.codeium/windsurf/mcp_config.json`:

```json
{
  "mcpServers": {
    "slashguard": {
      "command": "/Users/YOU/.slashguard/bin/sg",
      "args": ["serve"],
      "env": {
        "SG_LOG_FILE": "/Users/YOU/.slashguard/sg-mcp.log",
        "SG_EDITOR": "windsurf"
      }
    }
  }
}
```

### Claude Desktop

Open Settings → Developer → Edit Config, add:

```json
{
  "mcpServers": {
    "slashguard": {
      "command": "/Users/YOU/.slashguard/bin/sg",
      "args": ["serve"]
    }
  }
}
```

### Claude Code - macOS

```bash
claude mcp add --scope user slashguard -e SG_EDITOR=claude-code -- ~/.slashguard/bin/sg serve
```

### Claude Code - Windows (WSL2)

Install Claude Code inside your WSL2 Ubuntu terminal:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Then copy the SlashGuard binary and packs into WSL2:

```bash
# Copy binary (use sg-linux-arm64 for ARM, sg-linux-amd64 for x86_64)
mkdir -p ~/.slashguard/bin
cp /mnt/c/path/to/sg-linux-arm64 ~/.slashguard/bin/sg
chmod +x ~/.slashguard/bin/sg

# Copy packs
mkdir -p ~/.slashguard/packs
cp /mnt/c/path/to/release/*.sgpack ~/.slashguard/packs/

# Register with Claude Code
claude mcp add --scope user slashguard -e SG_EDITOR=claude-code -- ~/.slashguard/bin/sg serve
```

> **Important notes for WSL2:**
> - Use the **Linux** binary (not the Windows `.exe`). Check your architecture with `uname -m`:
>   `aarch64` = use `sg-linux-arm64`, `x86_64` = use `sg-linux-amd64`
> - The `W:` drive or mapped network drives may not be visible in WSL2 at `/mnt/w/`.
>   Copy files to `C:\temp\` first, then access them at `/mnt/c/temp/` in WSL2.
> - For best I/O performance, clone your repo into the WSL2 filesystem (`~/my-project`)
>   rather than working from `/mnt/c/...`.
> - The dashboard opens automatically in your Windows browser via `wslview`.

### Windows (any editor)

Use the full Windows path (with double backslashes in JSON) in the config. Edit `.cursor\mcp.json` (per-workspace) or `%APPDATA%\Cursor\User\globalStorage\mcp.json` (global):

```json
{
  "mcpServers": {
    "slashguard": {
      "command": "C:\\Users\\Dan\\.slashguard\\bin\\sg.exe",
      "args": ["serve"],
      "env": {
        "SG_EDITOR": "cursor"
      }
    }
  }
}
```

If you used `%LOCALAPPDATA%\SlashGuard\`:

```json
{
  "mcpServers": {
    "slashguard": {
      "command": "C:\\Users\\Dan\\AppData\\Local\\SlashGuard\\sg.exe",
      "args": ["serve"],
      "env": {
        "SG_EDITOR": "cursor"
      }
    }
  }
}
```

---

## 4. Add the Review Rule

The release zip includes a `rules/` folder with:

| File | Purpose | Editor |
|------|---------|--------|
| `rules/slashguard-review.mdc` | Runtime agent rule (teaches the AI how to run reviews) | Cursor, Windsurf |
| `rules/slashguard-claude-code-rule.md` | Runtime agent rule for Claude Code | Claude Code |
| `rules/slashguard-setup.mdc` | Install/update skill (one-time setup automation) | All |

### Cursor

```bash
cp rules/slashguard-review.mdc .cursor/rules/slashguard-review.mdc
```

Or for global rules: `~/.cursor/rules/slashguard-review.mdc`

**Windows:** Copy `rules\slashguard-review.mdc` to `.cursor\rules\slashguard-review.mdc` in your project (note backslash path separators).

### Windsurf

```bash
cp rules/slashguard-review.mdc .windsurfrules/slashguard-review.md
```

### Claude Code

```bash
mkdir -p .claude/rules
cp rules/slashguard-claude-code-rule.md .claude/rules/slashguard-review.md
```

> **Claude Code prompts you'll see on first use:**
>
> 1. **MCP server discovery** -- If the project has an `.mcp.json` (e.g. for Atlassian or other MCP servers):
>    ```
>    New MCP server found in .mcp.json: mcp-atlassian
>    MCP servers may execute code or access system resources.
>    ```
>    Select "Use this MCP server" or option 1. This doesn't affect SlashGuard (registered globally via `--scope user`).
>
> 2. **Tool approval** -- Claude Code asks permission before each MCP tool the first time:
>    ```
>    slashguard - review_start (MCP)
>    Do you want to proceed?
>      1. Yes
>    > 2. Yes, and don't ask again for slashguard - review_start
>      3. No
>    ```
>    Always pick **option 2** to auto-approve that tool for the project. You'll see this once per tool
>    (`review_start`, `review_scan`, `review_assess`, `look`, `review_report`, etc.).
>    After one full review cycle all tools are approved and it stops asking.

---

## 5. Verify

### Cursor / Windsurf

Restart your editor, then ask the AI agent:

> lint my working changes

The agent should call SlashGuard's `review_start` tool and return lint results.

### Claude Code

Before running your first lint, verify the MCP server is connected:

```bash
cd /path/to/your/project && claude
```

Then inside Claude Code, type:

```
/mcp
```

You should see `slashguard · ✔ connected` under **User MCPs**. If it shows `✘ failed`, see Troubleshooting below.

Once connected, try:

```
lint my working changes
```

### CLI

```bash
sg check --repo /path/to/your/project
```

---

## Editor URI Schemes

SlashGuard generates clickable file links in findings. Set `SG_EDITOR` in your MCP env to match your editor:

| Editor | `SG_EDITOR` value | URI Scheme | Notes |
|--------|--------------------|------------|-------|
| Cursor | `cursor` | `cursor://file/path:line:col` | Default |
| VS Code | `vscode` | `vscode://file/path:line:col` | |
| Windsurf | `windsurf` | `vscode://file/path:line:col` | VS Code compatible |
| Zed | `zed` | `zed://file/path:line:col` | |
| Claude Code | `claude-code` | Plain paths | Terminal renders `path:line` as clickable |

If not set, defaults to `vscode`.

You can also override the editor scheme in `.slashguard.yaml`:

```yaml
editor_scheme: cursor
```

---

## Troubleshooting

### Verify binary works

```bash
sg --version
# Should print the version, e.g. v1.0.0
```

### Verify MCP connection

**Cursor / Windsurf:**

1. Open Settings > MCP
2. Look for "slashguard" in the server list
3. Status should show "connected" or a green indicator
4. You should see 9 tools listed

If the server doesn't appear, check:
- Binary path in `mcp.json` is absolute and correct
- Binary has execute permission (`chmod +x`)
- On macOS: quarantine cleared (`xattr -d com.apple.quarantine`)

**Claude Code:**

Type `/mcp` inside Claude Code. SlashGuard should show as `✔ connected` under User MCPs.

If it shows `✘ failed`:

1. **Kill zombie processes** -- previous `sg serve` instances may be stuck:
   ```bash
   # macOS / Linux:
   pkill -f "sg serve"
   # Windows:
   taskkill /f /im sg.exe
   ```
   If that doesn't work (processes in uninterruptible state), log out and back in or reboot.

2. **Check the binary works**:
   ```bash
   echo '{}' | SG_EDITOR=claude-code sg serve
   # Should print a JSON-RPC error (expected) rather than hanging
   # Ctrl+C to exit
   ```

3. **Check registration**:
   ```bash
   claude mcp get slashguard
   # Should show: command: ~/.slashguard/bin/sg, args: serve, env: SG_EDITOR=claude-code
   ```

4. **Re-register if needed**:
   ```bash
   claude mcp remove --scope user slashguard
   claude mcp add --scope user slashguard -e SG_EDITOR=claude-code -- ~/.slashguard/bin/sg serve
   ```

### Verify rules are loaded

Ask the AI agent: `lint my changes in <your-repo>`

If it returns `rules_total: 0`, the packs weren't found. Check:
- `.sgpack` files are in `~/.slashguard/packs/`

You can also check via CLI:
```bash
sg index --repo /path/to/project
# Log should show loaded rules count
```

### Verify agent rule works

The agent rule (`slashguard-review.mdc`) teaches the AI how to use SlashGuard. Without it, the agent won't know what prompts map to what tools.

Test: ask the agent `review PR 123`. If the agent tries to read files manually instead of calling `review_start`, the rule isn't loaded.

### Common issues

| Issue | Fix |
|-------|-----|
| "command not found: sg" | Add `~/.slashguard/bin` to your PATH, or use absolute path in MCP config |
| "no functions in scope" | All changes are in non-code files (comments, configs), or test files (filtered out) |
| "repo is required" | Run Claude Code from inside a git repo, or tell it the path: "lint changes in /path/to/repo" |
| "not a git repository" | The directory passed to `review_start` has no `.git/`. Navigate to the actual repo root. |
| Lint returns 0 rules | Packs not found. Copy `.sgpack` files to `~/.slashguard/packs/` |
| Agent doesn't use SlashGuard | Copy the review rule to your editor's rules directory (see Step 4) |
| Claude Code uses wrong reviewer | Ensure `.claude/rules/slashguard-review.md` exists (not the Cursor `.mdc` file). The rule must say "use ONLY the SlashGuard MCP tools" at the top. |
| SlashGuard `✘ failed` in `/mcp` | Kill zombie `sg` processes: `pkill -f "sg serve"`. If stuck, reboot. |
| "Exec format error" on WSL2 | Wrong binary architecture. Run `uname -m` - use `sg-linux-arm64` for `aarch64`, `sg-linux-amd64` for `x86_64` |
| Windows: `sg.exe` not recognized | Add the directory containing `sg.exe` to your PATH, or use the full path in MCP config |
| Windows: `taskkill` fails | Process may already be stopped, or use Task Manager to end `sg.exe` manually |
| WSL2 can't access `W:` or mapped drives | Only `/mnt/c/` (and other local drives) are auto-mounted. Copy files to `C:\temp\` first, then access at `/mnt/c/temp/` |
| Dashboard not opening | Check port 19880 isn't in use. Try `curl http://localhost:19880` |
| Slow first review (~20s) | Normal: first run indexes your codebase (cached for subsequent runs). Subsequent reviews are ~5s |
| AI review varies between runs | Expected: depends on your IDE's current model and temperature settings |

### AI model considerations

SlashGuard's lint phase is deterministic (policy checks). The AI review phase uses whatever model your IDE provides:
- **Cursor**: uses the model selected in Settings > Models
- **Claude Desktop**: uses Claude (via Anthropic API)
- **Claude Code**: uses the configured model

Different models produce different AI review quality. Subagent behavior (whether they call context tools, how thoroughly they review) also varies by model. Lint findings are always consistent regardless of model.
