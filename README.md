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

On a fresh, stock Omarchy install, as your normal user:

```bash
git clone https://github.com/MichaelMuClaude/cc-os ~/.local/share/cc-os
~/.local/share/cc-os/install.sh
```

Read `install.sh` first: it can give your user passwordless root. It asks
before it does that, and before it removes any apps. `--yes` answers yes to
both, and `--no-sudoers`, `--keep-apps` and `--no-apps` skip the sudo rule,
the app removal and the Claude Desktop / Edge / Dropbox downloads. Run it
again after `git pull` to update. `uninstall.sh` undoes it (it leaves the
downloaded apps alone).

If an older, package-based CC/OS was installed on the machine, first run
`omarchy refresh config hypr/bindings.lua`: the packages appended their
shortcuts to that file, and `install.sh` replaces them with one line.

## What's here

- [`install.sh`](install.sh) / [`uninstall.sh`](uninstall.sh): the post-install
  script and its undo. The repo is linked at `~/.local/share/cc-os` and
  everything runs from there, so a `git pull` is the update.
- [`hypr/cc-os.lua`](hypr/cc-os.lua): the keyboard shortcuts below and
  natural touchpad scrolling, loaded by one line `install.sh` adds to
  `~/.config/hypr/bindings.lua`. [`hypr/cc-os-dropdown.lua`](hypr/cc-os-dropdown.lua)
  is the drop-down terminal panel.
- [`bin/`](bin/): the login session (`cc-os-session-start` opens Claude
  Desktop, keeps Omarchy's preinstalled apps and web apps trimmed down to a
  small set, starts Dropbox and syncs Claude's memory through it), the
  show / hide toggles behind the shortcuts, and the first-run downloads.
- [`cidata/`](cidata/): an autoinstall config for installing a stock Omarchy
  ISO unattended, with Chinese Pinyin input preconfigured.
- [`archive/`](archive/): the earlier packaging approach (two Arch packages
  and a patch that builds a custom installer ISO). Kept for reference, no
  longer maintained.

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

Apps opened from either drop-down panel (for example, an app Claude Code
launches) land on the main screen, and the panel puts itself away. Omarchy's
other window, workspace, monitor and system shortcuts are unchanged; `Super+K`
lists everything that is bound.

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
