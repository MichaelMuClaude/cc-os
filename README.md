# CC/OS

> **An OS with Claude Code pre-installed — with sudo.**

**Status: early but working.** CC/OS runs day to day on one laptop. It is
shipped as two Arch packages on top of Omarchy, plus a patch that builds a
CC/OS installer ISO. Expect rough edges and frequent changes.

CC/OS (Claude Code OS) is a minimal, Chromebook-like Linux desktop where
Claude (Desktop/Code) is the primary — eventually sole — interface, instead
of one app among many on a general-purpose desktop.

See [PLAN.md](PLAN.md) for where the idea is heading. It is a living doc,
not a spec.

## What's here

- [`packages/cc-os-claude-first-run`](packages/cc-os-claude-first-run/):
  makes Claude the main interface. It sets Claude Code as the default agent,
  opens Claude Desktop at login, installs the CC/OS keyboard shortcuts below,
  syncs Claude's memory through Dropbox, trims Omarchy's preinstalled apps
  and web apps down to a small set, and turns on natural touchpad scrolling.
- [`packages/cc-os-sudo-setup`](packages/cc-os-sudo-setup/): passwordless
  `sudo` for the `wheel` group, so Claude Code can operate the machine
  without a password prompt for every command.
- [`iso-build/`](iso-build/) and [`cidata/`](cidata/): the patch and
  autoinstall config for building a CC/OS installer ISO from
  `omarchy-iso`.

## Keyboard shortcuts

CC/OS keeps a small set of shortcuts, one per job, and leaves the rest to
Claude: instead of memorizing a key, you ask. Most of Omarchy's defaults for
preinstalled apps, web apps, widgets, notifications and floating windows are
removed.

| Key | What it does |
|---|---|
| Super+S | Show / hide Claude Desktop |
| Super+Space | Drop down the Claude Code console |
| Super+T | Drop down a terminal |
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
