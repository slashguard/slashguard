#!/bin/sh
set -e

# SlashGuard installer — macOS / Linux
# Usage: curl -sSL https://raw.githubusercontent.com/slashguard/slashguard/main/install.sh | sh

REPO="slashguard/slashguard"
INSTALL_DIR="$HOME/.slashguard"
BIN_DIR="$INSTALL_DIR/bin"
PACKS_DIR="$INSTALL_DIR/packs"

# --- Detect platform ---
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS" in
  darwin) ;;
  linux)  ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64)  ARCH="amd64" ;;
  amd64)   ;;
  arm64)   ;;
  aarch64) ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

PLATFORM="${OS}-${ARCH}"
ZIP_NAME="slashguard-${PLATFORM}.zip"
URL="https://github.com/${REPO}/releases/latest/download/${ZIP_NAME}"

echo "SlashGuard installer"
echo "  Platform: ${PLATFORM}"
echo "  Install:  ${INSTALL_DIR}"
echo ""

# --- Download ---
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading ${ZIP_NAME}..."
if command -v curl >/dev/null 2>&1; then
  curl -sSL -o "$TMP_DIR/$ZIP_NAME" "$URL"
elif command -v wget >/dev/null 2>&1; then
  wget -q -O "$TMP_DIR/$ZIP_NAME" "$URL"
else
  echo "Error: curl or wget required"; exit 1
fi

# --- Extract ---
echo "Extracting..."
unzip -qo "$TMP_DIR/$ZIP_NAME" -d "$TMP_DIR/sg"

# --- Install ---
mkdir -p "$BIN_DIR" "$PACKS_DIR"

cp "$TMP_DIR/sg/bin/sg" "$BIN_DIR/sg"
chmod +x "$BIN_DIR/sg"

# Packs: copy all .sgpack files
cp "$TMP_DIR/sg/packs/"*.sgpack "$PACKS_DIR/" 2>/dev/null || true

# Custom packs: only on first install
if [ ! -d "$PACKS_DIR/custom" ]; then
  cp -r "$TMP_DIR/sg/packs/custom" "$PACKS_DIR/custom" 2>/dev/null || true
fi

# Rules: copy to install dir so they survive temp cleanup
mkdir -p "$INSTALL_DIR/rules"
cp -r "$TMP_DIR/sg/rules/." "$INSTALL_DIR/rules/"

# --- PATH ---
if ! echo "$PATH" | tr ':' '\n' | grep -q '.slashguard/bin'; then
  SHELL_NAME=$(basename "$SHELL" 2>/dev/null || echo "sh")
  case "$SHELL_NAME" in
    zsh)  RC="$HOME/.zshrc" ;;
    bash) RC="$HOME/.bashrc" ;;
    fish) RC="$HOME/.config/fish/config.fish" ;;
    *)    RC="$HOME/.profile" ;;
  esac
  echo 'export PATH="$HOME/.slashguard/bin:$PATH"' >> "$RC"
  export PATH="$BIN_DIR:$PATH"
  echo "  Added to PATH via $RC"
fi

# --- Clean up old install locations ---
rm -f "$HOME/.local/bin/sg" 2>/dev/null || true
rm -f "$HOME/.local/bin/"*.sgpack 2>/dev/null || true
rm -rf "$HOME/.local/templates/" 2>/dev/null || true

# --- Verify ---
VERSION=$("$BIN_DIR/sg" --version 2>/dev/null || echo "unknown")
echo ""
echo "SlashGuard ${VERSION} installed to ${BIN_DIR}/sg"
echo ""
echo "Next steps:"
echo "  1. Configure MCP in your IDE (Cursor/Claude Code/Windsurf)"
echo "  2. Activate license: sg license activate <your-key>"
echo "  3. Restart your IDE"
echo ""
echo "Rule files are in: $INSTALL_DIR/rules/"
echo "Copy the ones for your IDE to your project's rules directory."
