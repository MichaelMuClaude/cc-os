# CC/OS — Plan (v0.1, discussion draft)

Last updated: 2026-10-21 (v0.4). This is a brainstorm snapshot, not a committed
spec. Nothing in here has been implemented.

## 1. Core idea

An OS where Claude (Desktop/Code) is the primary interface — not an app
you open, but the thing the machine boots into. Modeled loosely on the
Chromebook idea of "the browser is the OS," but with an agent instead
of a browser as the center of gravity.

## 2. Base distro

**Fork [Omarchy](https://github.com/basecamp/omarchy)** (Arch Linux +
Hyprland/Wayland, MIT-licensed, by DHH) rather than building from
scratch.

Why Omarchy specifically:
- Already ships pre-wired launchers for Claude Code, Codex, OpenCode,
  etc., with a top-bar "agents panel" (usage/account management,
  theme-sync to agents) — most of the hard integration work already
  exists.
- Already has branding tooling (`omarchy plymouth set`, screensaver /
  about-screen customization) that a fork can reuse for CC/OS's own
  identity instead of writing boot-splash tooling from scratch.
- Already adopted as a company-default OS elsewhere (37signals), so
  it's a maintained, real-world-used base, not an abandoned toy distro.
- A separate `omacom/omarchy-iso` repo exists specifically for building
  custom installer images, which is the mechanism CC/OS would use to
  ship its own ISO.

## 3. What changes from stock Omarchy

- **AI-first, not keyboard-shortcut-first.** Omarchy's whole design
  language is keyboard-driven — a large surface of Hyprland shortcuts
  you memorize to do things. CC/OS inverts that: instead of learning
  shortcuts for "all these things," you tell Claude to do them. The
  one dedicated hardware/key binding that remains is a **Claude hotkey
  on the Super key** — like the Copilot key on recent Windows
  keyboards — that summons Claude from anywhere, at any time, rather
  than a sprawl of per-action shortcuts to memorize.
- **Claude is the default/sole agent**, not one option among several
  agent launchers.
- **Custom rebrand**: boot splash, about screen, and the look of the
  (standard, PAM-based) login screen, using Omarchy's existing
  branding commands, pointed at CC/OS's own assets instead of
  Omarchy's.
- **Aggressive app reduction**: strip most pre-installed apps down to a
  minimal fallback set — terminal, file manager, a minimal browser —
  on the thesis that Claude's own growing capabilities (browser
  automation, document handling, etc.) keep absorbing what those apps
  used to be needed for.
- **System apps wrapped as Claude skills, not standalone GUI apps**:
  calculator, calendar, and similar everyday system utilities aren't
  shipped as separate apps a person opens — they're wrapped as skills
  Claude can call, so "do the math" or "what's on my calendar" is just
  a request to Claude, not a context switch to another window. The
  underlying functionality (and its data, e.g. calendar events) still
  needs to live somewhere on the system; the skill is the interface to
  it, not a replacement for having the data at all.
- **Chinese input preconfigured out of the box**: Fcitx5 + Pinyin,
  so a Chinese-speaking user doesn't have to configure it themselves
  after install. (Known Hyprland/Omarchy-specific gotcha already found
  during research: the system deliberately removes `Ctrl+Space` as the
  fcitx5 trigger key — the real toggle is `Super+I`. See personal
  memory `pattern-fcitx5-pinyin-hyprland-omarchy-setup.md` for the full
  writeup if this needs doing for real.)

## 4. First-run setup: guided sign-in, not a custom login screen

Dropped the earlier idea of replacing the OS login screen itself with
a "sign in with Claude" OAuth flow (that would have meant a custom
greeter bridging PAM and OAuth, and giving Claude passwordless sudo by
default — more architectural risk than the idea needs).

Instead: normal OS user account and login, like any Linux desktop.
After a person's first login, CC/OS walks them through a short, guided
setup — a wizard or first-run checklist — that gets them signed into
the **Claude Desktop app** and **Claude Code** themselves, so they land
in a working, authenticated environment without having to know what
either of those sign-in flows normally require.

## 5. Naming

- Working name: **CC/OS** (Claude Code OS). Repo slug: `cc-os` (GitHub
  doesn't allow `/` in repo names).
- Rejected: **agentOS** — heavily collided on GitHub, most notably
  `buildermethods/agent-os` (5,500+★), already a known quantity
  specifically within the Claude Code community.
- Checked and found *not* a real collision: `levisnakes/cc-os` (0★, an
  unrelated in-game OS for a Minecraft mod).
- Found and worth knowing about: [`Hostingglobal-Tech/claude-code-os`]
  (https://github.com/Hostingglobal-Tech/claude-code-os) (106★, MIT,
  actively maintained) — a bootable LiveUSB (Ventoy + Linux Mint XFCE)
  that auto-logs into a fullscreen window with Claude.ai and ChatGPT/
  Codex browser tabs. Real prior art, closest thing found to this idea
  so far, but meaningfully different in kind: it's a kiosk wrapping two
  *website* tabs for zero-setup chat access, not Claude Code wired into
  the OS with sudo, OAuth-as-login, or the agent actually operating the
  machine. Also found `dobralabs/ccos-ratos` (78★), which literally
  expands "CCOS" as "Claude Code OS" in its description but is just a
  welcome/setup kit for a paid course, not an OS at all.

## 6. Open questions / not yet decided

- Base: Arch (via Omarchy) vs. something else — Arch via Omarchy was
  the working assumption given the integration head start, but not
  independently re-litigated against e.g. an Ubuntu/Debian base.
- Exact minimal app set to keep (terminal, file manager, minimal
  browser was the first pass — not finalized).
- Which system utilities get the skill-wrapper treatment and which
  ones need an actual persistent backend/data store behind the skill
  (e.g. calendar needs real stored events, not just a stateless
  calculation) — not worked out yet.
- How the Claude hotkey actually surfaces Claude when summoned — an
  overlay window, a dropdown terminal, focus-switch to an
  always-running instance — not decided. Hyprland has the low-level
  global-hotkey/compositor hooks to bind a key system-wide; which of
  those summon behaviors to build on top of it is still open.
- Exact shape of the first-run guided sign-in (a GUI wizard vs. a
  terminal-based checklist vs. something embedded in the desktop
  shell) — not decided yet.
- No build, fork, or ISO work has started. This file is the discussion
  record, to be revised as the conversation continues.
