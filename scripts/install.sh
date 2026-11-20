#!/usr/bin/env bash
set -e

REPO="cwc-team/cotest-releases"
TEMP_DIR=$(mktemp -d)
VSIX_URL="https://github.com/${REPO}/releases/latest/download/cotest.vsix"
CHECKSUM_URL="https://github.com/${REPO}/releases/latest/download/checksums.txt"

echo "⚡ Downloading cotest extension..."
curl -sL "$VSIX_URL" -o "$TEMP_DIR/cotest.vsix"
curl -sL "$CHECKSUM_URL" -o "$TEMP_DIR/checksums.txt"

echo "🔒 Verifying SHA256 checksum..."
cd "$TEMP_DIR"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c checksums.txt
elif command -v shasum >/dev/null 2>&1; then
  shasum -a 256 -c checksums.txt
else
  echo "⚠️ Warning: Neither sha256sum nor shasum found, skipping checksum verification."
fi

echo "📦 Installing extension into VS Code..."
code --install-extension "$TEMP_DIR/cotest.vsix" --force

rm -rf "$TEMP_DIR"
echo "✅ cotest has been successfully installed! Please reload your VS Code window."
