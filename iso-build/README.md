# CC/OS custom ISO build patch

`omarchy-iso.patch` is a `git diff` against
[`omacom-io/omarchy-iso`](https://github.com/omacom-io/omarchy-iso)
at commit `81fd667b760ca331ad5f6122410275d042cf6610`
(2026-10-21). Applying it and building gives an Omarchy ISO that,
with no external USB drive and no fork of `basecamp/omarchy`:

- auto-detects the target disk and writes its own `cidata`-style
  autoinstall config at boot time (`cc-os-prepare-autoinstall`,
  wired into `omarchy-cidata-load`). Partition sizes are rounded down
  to whole MiB and the real logical sector size is read from the
  disk, since archinstall rejects anything else on real hardware.
- preconfigures Chinese Pinyin input (`omarchy_install.input_method`)
- installs two packages from a local pacman repo injected into the
  build:
  - [`cc-os-sudo-setup`](../packages/cc-os-sudo-setup/) --
    passwordless `sudo` for the `wheel` group, so Claude Code can
    operate the machine without per-command password prompts
  - [`cc-os-claude-first-run`](../packages/cc-os-claude-first-run/) --
    Claude Desktop as the main interface (see below)

See `PLAN.md` sections 3 and 4 in the repo root for the design
rationale.

## What `cc-os-claude-first-run` does

On first login it downloads the **latest** Claude Desktop, Microsoft
Edge (set as the default browser) and Dropbox, over the network, rather
than baking them into the image. Then, on every login:

- opens Claude Desktop full screen; `Super+S` summons / hides it
- skips Omarchy's "pick your default AI agent" prompt (a default-agent
  file in `/etc/skel`)
- appends `natural_scroll = true` and the `Super+S` binding to the
  user's Hyprland config (appended at login, not shipped in
  `/etc/skel`, because Omarchy's own package already owns those files)
- starts the Dropbox daemon and opens its sign-in page (the daemon only
  prints the link, it never opens a browser itself), with a notification
  because Claude's full-screen window covers the page
- once Dropbox reports "Up to date" three times in a row, points Claude
  Code's memory folder at `~/Dropbox/cc_Memory` with a symlink. Linking
  earlier would let Claude Code write into an empty folder that later
  collides with the synced one. Nothing is ever copied *into* Dropbox;
  an existing local memory folder is renamed aside, not uploaded.
- keeps the screensaver and idle lock off while the first-run install
  runs: a window opened while the screensaver is up lands on its hidden
  special workspace and is gone when it ends

## Building

```bash
git clone https://github.com/omacom-io/omarchy-iso.git
cd omarchy-iso
git checkout 81fd667b760ca331ad5f6122410275d042cf6610
git apply /path/to/omarchy-iso.patch

# Build both packages with makepkg (e.g. in an archlinux container:
# makepkg -f --skippgpcheck -d), then put them in a directory next to
# the omarchy-iso checkout named cc-os-local-repo and index it:
#   repo-add cc-os.db.tar.gz cc-os-sudo-setup-*.pkg.tar.zst \
#                            cc-os-claude-first-run-*.pkg.tar.zst
# The patch mounts that directory into the build container at /cc-os-repo.

bin/omarchy-iso-make --rc --no-boot-offer
```

`--rc` is required: the `stable` channel's `omarchy` package was
still on 4.0.6 as of this writing, which predates the Pinyin
`input_method` feature this patch relies on. Check
`pacman -Q omarchy` on whatever channel you build against before
assuming a feature is present -- the ISO build pipeline being current
doesn't mean the `omarchy` package it pulls is.

If you rebuild a local package without bumping its version, delete its
cached copy first (`~/.cache/omarchy/iso_rc/airootfs/var/cache/omarchy/mirror/offline/`,
owned by the container's root); `--keep-pkg-cache` otherwise reuses the
old file by name.
