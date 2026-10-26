#!/bin/bash
# CC/OS post-install. Run once on a stock Omarchy install, and again after a
# `git pull` to update. Run it as your normal user, not root: sudo asks for your
# password where it is needed.
#
#   git clone https://github.com/MichaelMuClaude/cc-os ~/.local/share/cc-os
#   ~/.local/share/cc-os/install.sh      (picks omarchy/install.sh on Omarchy)
#
# Read this file before running it: it can give your user passwordless root.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  --yes          Answer yes to every question (sudo rule, removing apps).
  --no-sudoers   Do not grant the wheel group passwordless sudo.
  --keep-apps    Do not remove Omarchy's preinstalled apps and web apps.
  --no-apps      Do not download Claude Desktop, Edge and Dropbox.
  -h, --help     Show this help.
EOF
}

yes=0 sudoers=1 trim=1 apps=1
for arg in "$@"; do
  case $arg in
    --yes) yes=1 ;;
    --no-sudoers) sudoers=0 ;;
    --keep-apps) trim=0 ;;
    --no-apps) apps=0 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

repo="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
link="$HOME/.local/share/cc-os"
hypr="$HOME/.config/hypr"
state="${XDG_STATE_HOME:-$HOME/.local/state}/cc-os"

say() { printf '==> %s\n' "$*"; }
ask() {
  (( yes )) && return 0
  [[ -t 0 ]] || return 1
  local reply; read -r -p "$1 [y/N] " reply
  [[ $reply == [yY]* ]]
}

(( EUID == 0 )) && { echo "Run install.sh as your normal user, not root." >&2; exit 1; }
[[ -f $hypr/bindings.lua ]] || { echo "No $hypr/bindings.lua: CC/OS sits on top of Omarchy, install that first." >&2; exit 1; }
mkdir -p "$state"

# The scripts and the Hyprland module run straight from the repo, through one stable
# path, so a `git pull` updates them and nothing is copied around.
say "Linking $link -> $repo"
mkdir -p "$(dirname "$link")"
if [[ -L $link ]]; then
  ln -sfn "$repo" "$link"
elif [[ -e $link ]]; then
  [[ $(readlink -f "$link") == "$repo" ]] || { echo "$link already exists and is not this repo." >&2; exit 1; }
else
  ln -s "$repo" "$link"
fi

# Passwordless sudo for the wheel group, so Claude Code can operate the machine
# without a password prompt for every command. Staged and checked with visudo
# before it is installed, so a malformed rule never reaches /etc/sudoers.d.
sudoers_file=/etc/sudoers.d/01-cc-os-wheel-nopasswd
if (( sudoers )) && ! sudo test -e "$sudoers_file"; then
  if ! id -nG | tr ' ' '\n' | grep -qx wheel; then
    say "You are not in the wheel group; skipping the sudo rule."
  elif ask "Let the wheel group run sudo without a password (Claude Code will have root)?"; then
    say "Granting passwordless sudo to wheel"
    staged=$(mktemp)
    printf '%%wheel ALL=(ALL:ALL) NOPASSWD: ALL\n' >"$staged"
    visudo -cf "$staged" >/dev/null || { rm -f "$staged"; echo "Refusing invalid sudoers content." >&2; exit 1; }
    sudo install -Dm440 -o root -g root "$staged" "$sudoers_file"
    rm -f "$staged"
  else
    say "Skipping the sudo rule"
  fi
fi

# One line at the end of bindings.lua loads hypr/cc-os.lua. Put your own overrides
# below it to win over CC/OS.
if ! grep -q ">>> cc-os" "$hypr/bindings.lua"; then
  say "Adding the CC/OS shortcuts to $hypr/bindings.lua"
  cp "$hypr/bindings.lua" "$hypr/bindings.lua.pre-cc-os"
  cat >>"$hypr/bindings.lua" <<'LUA'

-- >>> cc-os >>>
-- CC/OS shortcuts live in the cc-os repo (~/.local/share/cc-os/omarchy/hypr/cc-os.lua).
-- Your own overrides go below this block. pcall keeps the rest of the config loading
-- if the module ever fails.
local ok, err = pcall(dofile, (os.getenv("HOME") or "") .. "/.local/share/cc-os/omarchy/hypr/cc-os.lua")
if not ok then print("cc-os: " .. tostring(err)) end
-- <<< cc-os <<<
LUA
fi

# Claude Code as Omarchy's default agent, unless one is already chosen.
agent="$HOME/.config/omarchy/defaults/agent"
if [[ ! -s $agent ]]; then
  say "Setting Claude Code as the default agent"
  mkdir -p "$(dirname "$agent")"
  echo claude >"$agent"
fi

# Every graphical login: open Claude Desktop, keep the app list trimmed, start
# Dropbox and link Claude's memory folder into it.
say "Adding the login autostart entry"
mkdir -p "$HOME/.config/autostart"
cat >"$HOME/.config/autostart/cc-os-session.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=CC/OS session start
Exec=$link/omarchy/bin/cc-os-session-start
OnlyShowIn=Hyprland;
X-GNOME-Autostart-enabled=true
EOF

# cc-os-trim-apps runs at every login; this marker tells it to stand down.
if (( trim )) && ask "Remove the Omarchy apps and web apps CC/OS does without (see bin/cc-os-trim-apps)?"; then
  rm -f "$state/keep-apps"
else
  say "Keeping Omarchy's preinstalled apps"
  : >"$state/keep-apps"
fi

if (( apps )); then
  if pacman -Q claude-desktop >/dev/null 2>&1; then
    "$link/omarchy/bin/cc-os-install-dropbox" || say "Dropbox install failed; it will be retried at next login."
  else
    "$link/omarchy/bin/cc-os-install-apps" || say "Downloading the apps failed; it will be retried at next login."
  fi
fi

"$link/omarchy/bin/cc-os-trim-apps"

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl reload >/dev/null 2>&1 || true
  errors=$(hyprctl configerrors 2>/dev/null || true)
  [[ -n ${errors//[[:space:]]/} ]] && { echo "Hyprland reports config errors:" >&2; echo "$errors" >&2; }
fi

say "Done. Log out and back in to start the full CC/OS session; the shortcuts are active now."
