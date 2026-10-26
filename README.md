# CC/OS

> **An OS with Claude Code pre-installed — with sudo.**

**Status: early but working.** CC/OS runs day to day on one laptop. It is a
post-install script that turns a stock Omarchy install into CC/OS: no custom
ISO and no packages to build. Expect rough edges and frequent changes.

CC/OS (Claude Code OS) is a minimal, Chromebook-like Linux desktop where
Claude (Desktop/Code) is the primary — eventually sole — interface, instead
of one app among many on a general-purpose desktop.

See [PLAN.md](PLAN.md) for where the idea is heading. It is a living doc,
not a spec.

## Install

Two versions share this repo and one entry point. `install.sh` looks at the system
and hands over to the right one:

| System | Version | Desktop |
|---|---|---|
| Omarchy (Arch Linux) | [`omarchy/`](omarchy/) | Hyprland |
| Ubuntu 24.04+ and other Debian-based systems | [`ubuntu/`](ubuntu/) | GNOME |

As your normal user:

```bash
git clone https://github.com/MichaelMuClaude/cc-os ~/.local/share/cc-os
~/.local/share/cc-os/install.sh
```

Read the script first: it can give your user passwordless root. It asks before it
does that, before it adds third-party apt repositories (Ubuntu), and before it removes
any apps. `--yes` answers yes to every question, and `--no-sudoers`, `--keep-apps` and
`--no-apps` skip the sudo rule, the app removal and the Claude / Dropbox downloads
(`--no-shortcuts` skips GNOME's shortcuts on Ubuntu). Run it again after `git pull` to
update. `uninstall.sh` undoes it and leaves the downloaded apps alone. Set
`CC_OS_TARGET=omarchy` or `CC_OS_TARGET=ubuntu` to pick a version by hand.

If an older, package-based CC/OS was installed on an Omarchy machine, first run
`omarchy refresh config hypr/bindings.lua`: the packages appended their shortcuts to
that file, and `install.sh` replaces them with one line.

The two versions give the same shortcuts (table below). The Ubuntu version is newer
and has had less testing; see [ubuntu/README.md](ubuntu/README.md) for how it works and
what differs.

## What's here

- [`install.sh`](install.sh) / [`uninstall.sh`](uninstall.sh): pick the version for
  this system. The repo is linked at `~/.local/share/cc-os` and everything runs from
  there, so a `git pull` is the update.
- [`omarchy/`](omarchy/): the Omarchy version. `hypr/cc-os.lua` holds every shortcut
  (loaded by one line added to `~/.config/hypr/bindings.lua`), `hypr/cc-os-dropdown.lua`
  is the drop-down terminal panel, and `bin/` has the login session, the show / hide
  toggles and the first-run downloads.
- [`ubuntu/`](ubuntu/): the Ubuntu version. `bin/cc-os-gnome-keys` sets the shortcuts in
  GNOME, and a small GNOME Shell extension in `gnome/` does the window work.
- [`shared/bin/`](shared/bin/): the Dropbox status and memory-link helpers both versions use.
- [`cidata/`](cidata/): an autoinstall config for installing a stock Omarchy
  ISO unattended, with Chinese Pinyin input preconfigured.
- [`archive/`](archive/): the earlier packaging approach (two Arch packages
  and a patch that builds a custom installer ISO). Kept for reference, no
  longer maintained.
- `bin` and `hypr` at the top level are links into `omarchy/`, so installs made before
  the split keep working.

## Keyboard shortcuts

CC/OS keeps a small set of shortcuts, one per job, and leaves the rest to
Claude: instead of memorizing a key, you ask. Most of Omarchy's defaults for
preinstalled apps, web apps, widgets, notifications and floating windows are
removed.

| Key | What it does |
|---|---|
| Super+S | Show / hide Claude Desktop |
| Super+Space | Open Claude Desktop |
| Super+T | Drop down the Claude Code console |
| Super+Shift+T | Drop down a plain terminal |
| Super+B | Show / hide the browser |
| Super+E | File manager |
| Super+O | App list |
| Super+M | Omarchy menu |
| Super+Return | Tile every window; press again to widen the focused one |
| Super+F | Full screen |
| Super+= / Super+- | Grow / shrink the focused window (add Alt for a little, Ctrl for a lot) |
| Super+Tab | Next window |
| Alt+Tab | Next workspace |
| Super+1 … Super+0 | Go to workspace 1–10 |
| Super+Shift+1 … Super+Shift+0 | Move the window to workspace 1–10 |
| Super+Q / Super+W | Close the window |
| Super+L | Lock the screen |
| Super+C / Super+V / Super+X | Copy / paste / cut, in every app |
| Super+Shift+S | Screenshot |
| Ctrl+Space | Switch input language |

On Omarchy, apps opened from either drop-down panel (for example, an app Claude Code
launches) land on the main screen, and the panel puts itself away. Omarchy's other
window, workspace, monitor and system shortcuts are unchanged; `Super+K` lists
everything that is bound.

On Ubuntu, Super+M opens GNOME's overview instead of Omarchy's menu, "tile every
window" lays the windows out in a grid, and Super+C / V / X are left alone (GNOME
can't remap them for every app). See [ubuntu/README.md](ubuntu/README.md).

## Why

The person behind this project noticed they spend roughly 80% of their
computer time inside the Claude desktop app already, and that Claude's
own capabilities (browser, file handling, an Office-like suite, etc.)
keep absorbing functionality that used to require separate apps. The
bet is that this trend continues, so an OS that leans all the way into
it — rather than treating Claude as a guest app on top of a traditional
desktop — becomes a reasonable, even obvious, thing to want.

## Naming note

GitHub repo slugs can't contain `/` (it's the owner/repo separator), so
the repo itself is `cc-os`. The brand name is written **CC/OS** — same
idea as Anthropic's own use of `/` in their logo, just not something a
URL path can carry literally.
