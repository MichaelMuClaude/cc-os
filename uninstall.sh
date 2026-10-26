#!/bin/bash
# Undo install.sh: drop the shortcuts, the login autostart entry and the sudo rule.
# It does not uninstall Claude Desktop, Edge or Dropbox, bring back the apps that
# were removed, or delete the repo. Log out afterwards to stop the running helpers.
set -euo pipefail

hypr="$HOME/.config/hypr"
link="$HOME/.local/share/cc-os"

if grep -q ">>> cc-os" "$hypr/bindings.lua" 2>/dev/null; then
  echo "==> Removing the CC/OS block from $hypr/bindings.lua"
  sed -i '/^-- >>> cc-os >>>$/,/^-- <<< cc-os <<<$/d' "$hypr/bindings.lua"
fi

rm -f "$HOME/.config/autostart/cc-os-session.desktop"
[[ -L $link ]] && rm -f "$link"

sudoers_file=/etc/sudoers.d/01-cc-os-wheel-nopasswd
if sudo test -e "$sudoers_file"; then
  echo "==> Removing the passwordless sudo rule"
  sudo rm -f "$sudoers_file"
fi

command -v hyprctl >/dev/null 2>&1 && hyprctl reload >/dev/null 2>&1 || true
echo "==> Done."
