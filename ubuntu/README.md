# CC/OS on Ubuntu

The Ubuntu version of CC/OS: the same Claude-first shortcuts as the Omarchy version, on
GNOME. It is built for Ubuntu 24.04 and newer (GNOME 46+) and other Debian-based
systems running GNOME on Wayland. Anthropic's Claude Desktop beta also supports 22.04,
but the shell extension needs GNOME 46.

**Status: written, not yet run on a real Ubuntu machine.** Everything here passed a
syntax check and the Omarchy side was tested; the GNOME-specific parts below were not.

## What `install.sh` does

- Links the repo at `~/.local/share/cc-os`; everything runs from there.
- Installs the base packages (`curl`, `gnupg`, `libglib2.0-bin`, `libnotify-bin`,
  `dconf-cli`, `python3`, `alacritty`).
- Asks before giving the `sudo` group passwordless sudo (`/etc/sudoers.d/01-cc-os-nopasswd`,
  checked with `visudo` first).
- Asks before adding Anthropic's two apt repositories (Claude Desktop and Claude Code,
  from `downloads.claude.ai`) and installing both, plus `nautilus-dropbox`. Each
  downloaded signing key is checked against Anthropic's published fingerprint
  (`31DD DE24 DDFA B679 F42D 7BD2 BAA9 29FF 1A7E CACE`) before apt is told to trust it.
- Installs the GNOME Shell extension (a link into `~/.local/share/gnome-shell/extensions`)
  and enables it.
- Sets the keyboard shortcuts with `gsettings`, saving every old value first.
- Adds a login autostart entry: start Dropbox, link Claude's memory folder into it, open
  Claude Desktop.
- Asks before removing Ubuntu apps CC/OS does without (LibreOffice, Rhythmbox,
  Transmission, Remmina, Thunderbird). Decline and it leaves them, and the login
  script leaves them too.

`uninstall.sh` restores the saved shortcut values, removes the extension, the autostart
entry and the sudo rule. Log out and back in after installing or uninstalling.

## How the shortcuts work

GNOME can't be scripted from outside for window actions on Wayland, so the work is split:

- **Native GNOME keys** (`cc-os-gnome-keys`): close (Super+Q / W), full screen,
  Super+Tab, workspaces 1–10 and moving windows to them, app list (Super+O), overview
  (Super+M), screenshot, input language (Ctrl+Space). It also frees the keys GNOME and
  the Ubuntu dock would otherwise take (Super+1–9, Super+S, Super+Space).
- **Custom shortcuts** run the scripts in `bin/`: Claude Desktop (Super+S / Super+Space),
  the drop-down Claude Code console and plain terminal (Super+T / Super+Shift+T), the
  browser toggle (Super+B), Files (Super+E), tile / widen (Super+Return), resize
  (Super+= / Super+-, with Alt or Ctrl), next workspace (Alt+Tab).
- **The extension** (`gnome/cc-os-shell@cc-os.github.io`) exports `org.ccos.Shell` on the
  session bus. The scripts call it with `gdbus` (through `bin/cc-os-shell`) to show,
  hide, place and resize windows. When it answers `none` (no such window yet), the
  script launches the app itself.

The drop-down panels are `alacritty` windows with the class `cc-os.console` and
`cc-os.dropdown`; the extension recognises them by that class and places them in the
top half of the screen, centred, always on top and on every workspace.

## Differences from the Omarchy version

- No Edge install: Super+B toggles whatever the default browser is.
- Super+M opens GNOME's overview, not Omarchy's menu.
- "Tile every window" arranges them in a grid; GNOME has no automatic tiling.
- Super+C / V / X are not remapped.
- No natural-scroll setting here: GNOME already has one under Settings > Mouse & Touchpad.

## What to check on a real machine

1. `./install.sh`, then log out and back in (a new extension loads at login on Wayland).
2. `gnome-extensions list --enabled` shows `cc-os-shell@cc-os.github.io`, and
   `gdbus call --session --dest org.ccos.Shell --object-path /org/ccos/Shell --method org.ccos.Shell.NextWorkspace`
   switches workspace. If not, `journalctl -f /usr/bin/gnome-shell` shows why the
   extension failed to load.
3. Super+T opens a terminal running `claude` at the top of the screen, and the same key
   hides it. Super+Shift+T does the same for a plain shell.
4. Super+S / Super+Space bring up Claude Desktop. If they open a second copy instead,
   the window's class doesn't contain `claude`: check it with Looking Glass
   (Alt+F2, `lg`, Windows tab) and adjust the patterns in `bin/cc-os-claude-toggle`.
5. Super+Shift+1 moves the focused window to workspace 1. If it doesn't, GNOME wants
   the shifted symbol (`exclam`) in the accelerator; change it in `bin/cc-os-gnome-keys`.
6. `gnome-keys restore` (or `uninstall.sh`) puts every shortcut back.
