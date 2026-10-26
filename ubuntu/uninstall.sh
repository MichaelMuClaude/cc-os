#!/bin/bash
# Undo install.sh: restore GNOME's shortcuts, remove the shell extension, the login
# autostart entry and the sudo rule. It does not uninstall Claude Desktop, Claude Code
# or Dropbox, bring back removed apps, or delete the repo. Log out afterwards.
set -euo pipefail

link="$HOME/.local/share/cc-os"
extension=cc-os-shell@cc-os.github.io

if [[ -x $link/ubuntu/bin/cc-os-gnome-keys ]]; then
  echo "==> Restoring GNOME's keyboard shortcuts"
  "$link/ubuntu/bin/cc-os-gnome-keys" restore
fi

enabled=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || true)
if [[ -n $enabled ]]; then
  new=$(ENABLED="$enabled" UUID="$extension" python3 -c '
import ast, os
l = ast.literal_eval(os.environ["ENABLED"].replace("@as ", ""))
print([u for u in l if u != os.environ["UUID"]])')
  gsettings set org.gnome.shell enabled-extensions "$new"
fi
rm -f "$HOME/.local/share/gnome-shell/extensions/$extension"

rm -f "$HOME/.config/autostart/cc-os-session.desktop"
[[ -L $link ]] && rm -f "$link"

sudoers_file=/etc/sudoers.d/01-cc-os-nopasswd
if sudo test -e "$sudoers_file"; then
  echo "==> Removing the passwordless sudo rule"
  sudo rm -f "$sudoers_file"
fi
echo "==> Done."
