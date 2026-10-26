#!/bin/bash
# CC/OS post-install for Ubuntu (and other Debian-based systems) running GNOME. Run it
# once, and again after a `git pull` to update. Run it as your normal user, not root:
# sudo asks for your password where it is needed.
#
#   git clone https://github.com/MichaelMuClaude/cc-os ~/.local/share/cc-os
#   ~/.local/share/cc-os/install.sh      (picks ubuntu/install.sh on Ubuntu)
#
# Read this file before running it: it can give your user passwordless root and it
# adds Anthropic's apt repositories.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  --yes          Answer yes to every question (sudo rule, apt repositories, removing apps).
  --no-sudoers   Do not give the sudo group passwordless sudo.
  --keep-apps    Do not remove Ubuntu's preinstalled apps (see bin/cc-os-trim-apps).
  --no-apps      Do not install Claude Desktop, Claude Code and Dropbox.
  --no-shortcuts Do not change GNOME's keyboard shortcuts or install the shell extension.
  -h, --help     Show this help.
EOF
}

yes=0 sudoers=1 trim=1 apps=1 shortcuts=1
for arg in "$@"; do
  case $arg in
    --yes) yes=1 ;;
    --no-sudoers) sudoers=0 ;;
    --keep-apps) trim=0 ;;
    --no-apps) apps=0 ;;
    --no-shortcuts) shortcuts=0 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

repo="$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")"
link="$HOME/.local/share/cc-os"
bin="$link/ubuntu/bin"
state="${XDG_STATE_HOME:-$HOME/.local/state}/cc-os"
extension=cc-os-shell@cc-os.github.io

# Anthropic signs its apt repositories with this key; the downloaded keys are checked
# against it before apt is told to trust them.
anthropic_fingerprint=31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE

say() { printf '==> %s\n' "$*"; }
ask() {
  (( yes )) && return 0
  [[ -t 0 ]] || return 1
  local reply; read -r -p "$1 [y/N] " reply
  [[ $reply == [yY]* ]]
}

(( EUID == 0 )) && { echo "Run install.sh as your normal user, not root." >&2; exit 1; }
command -v apt-get >/dev/null 2>&1 || { echo "apt-get not found: this is the Ubuntu / Debian version of CC/OS." >&2; exit 1; }
mkdir -p "$state"

# The scripts and the shell extension run straight from the repo, through one stable
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

# Passwordless sudo for the sudo group, so Claude Code can operate the machine without
# a password prompt for every command. Staged and checked with visudo before it is
# installed, so a malformed rule never reaches /etc/sudoers.d.
sudoers_file=/etc/sudoers.d/01-cc-os-nopasswd
if (( sudoers )) && ! sudo test -e "$sudoers_file"; then
  if ! id -nG | tr ' ' '\n' | grep -qx sudo; then
    say "You are not in the sudo group; skipping the sudo rule."
  elif ask "Let the sudo group run sudo without a password (Claude Code will have root)?"; then
    say "Granting passwordless sudo to the sudo group"
    staged=$(mktemp)
    printf '%%sudo ALL=(ALL:ALL) NOPASSWD: ALL\n' >"$staged"
    visudo -cf "$staged" >/dev/null || { rm -f "$staged"; echo "Refusing invalid sudoers content." >&2; exit 1; }
    sudo install -Dm440 -o root -g root "$staged" "$sudoers_file"
    rm -f "$staged"
  else
    say "Skipping the sudo rule"
  fi
fi

# add_anthropic_repo <name> <key url> <key path> <apt line>: downloads the signing key,
# refuses it unless it is Anthropic's, then registers the repository.
add_anthropic_repo() {
  local name=$1 key_url=$2 key_path=$3 line=$4 tmp fingerprints
  tmp=$(mktemp)
  curl -fsSL "$key_url" -o "$tmp"
  fingerprints=$(gpg --show-keys --with-colons "$tmp" | awk -F: '/^fpr:/ {print $10}')
  if ! grep -qx "$anthropic_fingerprint" <<<"$fingerprints"; then
    rm -f "$tmp"; echo "The $name signing key is not Anthropic's; not trusting it." >&2; return 1
  fi
  sudo install -Dm644 "$tmp" "$key_path"
  rm -f "$tmp"
  echo "$line" | sudo tee "/etc/apt/sources.list.d/$name.list" >/dev/null
}

# What the scripts and shortcuts themselves need: gdbus and gsettings, notify-send, the
# terminal behind the drop-down panels, and the tools used below.
say "Installing the base packages"
sudo apt-get update
sudo apt-get install -y curl gnupg libglib2.0-bin libnotify-bin dconf-cli python3 alacritty

if (( apps )) && ask "Add Anthropic's apt repositories and install Claude Desktop, Claude Code and Dropbox?"; then
  say "Installing Claude Desktop, Claude Code and Dropbox"
  sudo apt-get install -y nautilus-dropbox
  add_anthropic_repo claude-desktop https://downloads.claude.ai/claude-desktop/key.asc \
    /usr/share/keyrings/claude-desktop-archive-keyring.asc \
    "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    || say "Skipping Claude Desktop"
  add_anthropic_repo claude-code https://downloads.claude.ai/keys/claude-code.asc \
    /etc/apt/keyrings/claude-code.asc \
    "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/stable stable main" \
    || say "Skipping Claude Code"
  sudo apt-get update
  for pkg in claude-desktop claude-code; do
    [[ -e /etc/apt/sources.list.d/$pkg.list ]] && sudo apt-get install -y "$pkg" || true
  done
else
  say "Skipping the app downloads"
fi

if (( shortcuts )); then
  # The shell extension does the window work GNOME can't script from outside. A newly
  # installed extension is only picked up at the next login on Wayland.
  say "Installing the GNOME Shell extension"
  mkdir -p "$HOME/.local/share/gnome-shell/extensions"
  ln -sfn "$link/ubuntu/gnome/$extension" "$HOME/.local/share/gnome-shell/extensions/$extension"
  enabled=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null || true)
  if [[ -n $enabled ]]; then
    new=$(ENABLED="$enabled" UUID="$extension" python3 -c '
import ast, os
l = ast.literal_eval(os.environ["ENABLED"].replace("@as ", ""))
if os.environ["UUID"] not in l:
    l.append(os.environ["UUID"])
print(l)')
    gsettings set org.gnome.shell enabled-extensions "$new"
  fi

  say "Setting the CC/OS keyboard shortcuts (the old values are saved for uninstall.sh)"
  "$bin/cc-os-gnome-keys" apply
fi

# Every graphical login: open Claude Desktop, keep the app list trimmed, start Dropbox
# and link Claude's memory folder into it.
say "Adding the login autostart entry"
mkdir -p "$HOME/.config/autostart"
cat >"$HOME/.config/autostart/cc-os-session.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=CC/OS session start
Exec=$bin/cc-os-session-start
OnlyShowIn=GNOME;
X-GNOME-Autostart-enabled=true
EOF

# cc-os-trim-apps runs at every login; this marker tells it to stand down.
if (( trim )) && ask "Remove the Ubuntu apps CC/OS does without (see ubuntu/bin/cc-os-trim-apps)?"; then
  rm -f "$state/keep-apps"
else
  say "Keeping Ubuntu's preinstalled apps"
  : >"$state/keep-apps"
fi
"$bin/cc-os-trim-apps"

say "Done. Log out and back in: GNOME loads the shell extension at login, and the shortcuts that need it work after that."
