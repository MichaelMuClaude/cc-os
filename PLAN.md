# CC/OS — Plan (v0.1, discussion draft)

Last updated: 2026-10-21 (v0.9). This is a brainstorm snapshot, not a committed
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
- **Office suite replaced by the formats Claude already works in
  natively**, not a bundled Office/LibreOffice-alike:
  - **Word → Markdown.** Documents are plain `.md` files Claude reads
    and writes directly, not a binary format requiring a dedicated
    editor.
  - **Excel → a database.** Structured/tabular data lives in an actual
    database (schema, queries) that Claude operates on directly,
    instead of a spreadsheet GUI as the interface to the data.
  - **PowerPoint → HTML.** Presentations/visual decks are HTML (and
    this repo's own early planning already leans this way — Claude's
    Artifact tooling already produces HTML decks/pages as its default
    output for this kind of thing).
  Rendering/viewing these still needs something — e.g. the minimal
  browser already in the fallback app set can render the Markdown/
  HTML, and a thin UI can sit on top of the database for human
  browsing — but authoring and editing routes through Claude, not a
  dedicated Office-style app.
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
  after install. **Fully solved upstream as of Omarchy 4.5.0rc1
  (released 2026-10-20) — no fork needed for this feature at all.**
  DHH's team merged first-class Japanese/Chinese/Korean input-method
  support directly into the installer on 2026-10-15, six days before
  this was tested: `fcitx5-chinese-addons` (and the other CJK engines)
  now ship unconditionally in Omarchy's base package set, the
  installer's own autoinstall config accepts an explicit
  `input_method` field, and the right fcitx5 profile gets written
  during provisioning — before fcitx5 ever starts for that user, which
  sidesteps the one real gotcha found while reverse-engineering this
  (undocumented, pre-4.5 behavior): fcitx5 caches its input-method
  list in memory once running, and neither editing the profile file
  nor fcitx5's own `fcitx5-remote -r` reload command refreshes a
  *running* daemon — only a fresh process start does. The switch key
  is `Super+I` (not `Ctrl+Space`, which an earlier version of this note
  claimed based on 4.0.6 behavior before this feature existed upstream
  at all).

  **Verified end-to-end today**, stock official ISO, zero customization:
  downloaded `omarchy-4.5.0rc1.iso` from `iso.omarchy.org` (SHA256
  checked against the published release hash), built a `cidata`
  autoinstall drive (the standard cloud-init NoCloud mechanism Omarchy's
  own installer already supports — see
  [`manual/unattended-installs`](https://omarchy.org/manual/unattended-installs/))
  with `omarchy_install.input_method` set to `"pinyin"` in
  `user_configuration.json`, booted a VM with the ISO plus that drive
  attached, and got a **fully unencrypted, fully unattended** install —
  no keyboard touched, no prompts answered. First login: `cat
  ~/.config/fcitx5/profile` already shows `DefaultIM=pinyin`, `Super+I`
  switches the top-bar indicator to the fcitx5 Pinyin icon, and typing
  in Chromium's address bar pops a real candidate window (`1.你好
  2.👋 3.拟好...`) that commits correctly.

  **One non-obvious infra gotcha hit along the way**: the `cidata`
  drive must be attached as a **USB mass-storage device**
  (`-device usb-storage` in QEMU terms, `--targetbus usb` in
  `virt-install`), not as a SATA CD-ROM — a FAT-formatted raw image
  attached as `device=cdrom` fails with `mount: can't read superblock`
  and the installer silently falls back to the interactive wizard.
  This is literally how Omarchy's own CI integration tests attach it
  (`test/integration.d/base-test.sh` in `omacom/omarchy-iso`), so it's
  a one-line fix once you know to look there.

  **What CC/OS actually needs to do for this feature, given the above
  is now entirely upstream's job**: maintain a `user_configuration.json`
  template (a working one, tested today, is committed in this repo —
  see `cidata/`) with `input_method: "pinyin"` pre-set, and attach it
  alongside whatever stock Omarchy ISO CC/OS ships install media for.
  No fork, no patch, no custom package, no touching fcitx5 config at
  all. If CC/OS ever wants this forced rather than merely defaulted
  (so a non-Chinese-layout install still gets Pinyin available, or to
  support a language CC/OS cares about that Omarchy's own installer
  doesn't yet default to for a given locale), that's a one-field change
  in the same JSON file, still no fork.

  Full investigation — including the now-obsolete GUI-vs-CLI debugging
  trail from before 4.5.0rc1 existed, and why earlier notes here were
  wrong twice (once claiming only the GUI path worked, once claiming
  `Super+I` was undocumented vaporware) — is in personal memory
  `pattern-fcitx5-pinyin-hyprland-omarchy-setup.md`. That history is
  kept for the record, not because any of it is still the right way to
  do this on 4.5.0rc1 or later.

- **Claude Code gets full, unrestricted, passwordless root — deliberate,
  not a default left unexamined.** This is the direct consequence of
  CC/OS's core thesis (§1): the AI is the primary operator of the
  machine, not a human standing by to approve each privileged action.
  A model where Claude Code has to request human confirmation for
  system-level work — or only gets a narrow allowlist of pre-approved
  commands — reintroduces exactly the human-in-the-loop bottleneck
  CC/OS exists to remove, just relocated to the permission layer
  instead of the command-shortcut layer. The standard "least privilege,
  human approves anything irreversible" model is Omarchy's own
  philosophy for *its* agent integration (see
  `default/agents/skills/omarchy/SKILL.md`'s Privilege Escalation
  section: `sudo` when a terminal is visible for a password prompt,
  `pkexec` otherwise) — a reasonable choice for an OS built around a
  human operator who occasionally delegates to an agent, but not the
  choice CC/OS is making, since CC/OS inverts who the primary operator
  is.

  **`custom_commands` turned out not to work — Omarchy's orchestrator
  never reads it.** The field is real and documented upstream in
  archinstall, but `omarchy-iso`'s orchestrator
  (`configs/airootfs/usr/share/omarchy-iso/orchestrator/*.py`)
  completely reimplements the install flow on top of archinstall's
  low-level primitives and never calls the upstream entrypoint that
  processes `custom_commands` — confirmed by grepping the orchestrator
  source for zero hits. The cidata answer file's top-level `"packages"`
  array has the same problem: nothing reads it either. Both looked like
  the obvious, no-fork way to do this and both are silently inert.

  **What actually works: a standalone Arch package
  (`cc-os-sudo-setup`), built outside both `basecamp/omarchy` and
  `omarchy-pkgs`, injected into the ISO build through a local pacman
  repo.** It ships a oneshot systemd service
  (`cc-os-wheel-nopasswd.service`) that unconditionally writes
  `/etc/sudoers.d/01-cc-os-wheel-nopasswd`
  (`%wheel ALL=(ALL:ALL) NOPASSWD: ALL`, staged and `visudo -cf`
  syntax-checked before install) at every boot, guarded idempotent via
  `ConditionPathExists=!/etc/sudoers.d/01-cc-os-wheel-nopasswd`. Works
  with `defer_provisioning: true` the same way the `custom_commands`
  approach would have, since the rule targets the `wheel` *group* and
  the service just runs again (harmlessly) after the deferred
  first-boot account creation puts the new user in `wheel` — Omarchy's
  own default there is `/etc/sudoers.d/00-omarchy-wheel`
  (`%wheel ALL=(ALL:ALL) ALL`, password required); `sudoers.d` applies
  in filename order so `01-...` wins.

  Getting the package to actually land on the target system took two
  more wrong turns, both now fixed: the orchestrator only installs
  packages listed in a static file baked into the ISO at build time
  (`omarchy-base.packages`) — a near-identical-looking
  `omarchy-other.packages` file sits right next to it and is never
  read by anything, a dead end that looked like the right answer; and
  a `post_install()` function written directly in the package's
  PKGBUILD is build-time-only and never runs as a pacman install hook
  unless wired through a separate `.install` file, so the
  systemd-enable step silently never fired — fixed by shipping the
  `multi-user.target.wants` enable symlink directly in the package
  instead of relying on any install-time scriptlet. Full build recipe
  and every pitfall hit along the way (IFS/`read` bug in the
  autoinstall disk-detection script, the stale `--keep-pkg-cache`
  trap, needing `--rc` to get an `omarchy` package new enough to have
  the Pinyin feature from §3) is in personal memory
  `reference-omarchy-custom-iso-build-recipe.md`.

  **Verified end-to-end in a real VM install (2026-10-21, no external
  USB, full disk, UEFI)**: `sudo -n whoami` returns `root` with zero
  password prompt on first login.

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

Note this is separate from the headline tagline ("an OS with Claude
Code pre-installed — with sudo"): dropping the custom OAuth-login-screen
idea doesn't mean dropping sudo access for Claude Code. Claude Code
still comes pre-installed with sudo on the normal local account — what
got dropped was *tying that to a custom login flow*, not the
permission itself. Exact mechanism is decided — see §3.

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
- Which database for the Excel replacement (SQLite as a per-user local
  default is the obvious first guess, not decided) and what, if
  anything, provides a human-friendly grid view on top of it for
  someone who still wants to eyeball a table.
- How the Claude hotkey actually surfaces Claude when summoned — an
  overlay window, a dropdown terminal, focus-switch to an
  always-running instance — not decided. Hyprland has the low-level
  global-hotkey/compositor hooks to bind a key system-wide; which of
  those summon behaviors to build on top of it is still open.
- Exact shape of the first-run guided sign-in (a GUI wizard vs. a
  terminal-based checklist vs. something embedded in the desktop
  shell) — not decided yet.
- No fork or custom ISO work has started. One concrete, tested artifact
  does exist in this repo now — a working `cidata` autoinstall template
  (see `cidata/`) that preconfigures Chinese Pinyin input on a
  completely stock Omarchy 4.5.0rc1 ISO, verified in a real VM install
  — but it's a config file attached alongside the official installer,
  not a fork or a custom image. This file is otherwise still the
  discussion record, to be revised as the conversation continues.
