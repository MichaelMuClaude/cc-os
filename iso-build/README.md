# CC/OS custom ISO build patch

`omarchy-iso.patch` is a `git diff` against
[`omacom-io/omarchy-iso`](https://github.com/omacom-io/omarchy-iso)
at commit `81fd667b760ca331ad5f6122410275d042cf6610`
(2026-10-21). Applying it and building gives an Omarchy ISO that,
with no external USB drive and no fork of `basecamp/omarchy`:

- auto-detects the target disk and writes its own `cidata`-style
  autoinstall config at boot time (`cc-os-prepare-autoinstall`,
  wired into `omarchy-cidata-load`)
- preconfigures Chinese Pinyin input (`omarchy_install.input_method`)
- installs [`cc-os-sudo-setup`](../packages/cc-os-sudo-setup/)
  (passwordless `sudo` for the `wheel` group), via a local pacman
  repo injected into the build

See `PLAN.md` sections 3 and 4 in the repo root for the design
rationale, and personal-memory file
`reference-omarchy-custom-iso-build-recipe.md` for the full build
recipe and every pitfall hit getting here (none of which are
reproduced in this patch's commit history, since it's a working-tree
diff, not a commit log).

## Building

```bash
git clone https://github.com/omacom-io/omarchy-iso.git
cd omarchy-iso
git checkout 81fd667b760ca331ad5f6122410275d042cf6610
git apply /path/to/omarchy-iso.patch

# build the cc-os-sudo-setup package and a local pacman repo for it —
# see ../packages/cc-os-sudo-setup/, build with makepkg, then
# repo-add a database file into a directory mounted at /cc-os-repo
# inside the build container (see the -v line the patch adds to
# bin/omarchy-iso-make's DOCKER_ARGS)

bin/omarchy-iso-make --rc --no-boot-offer
```

`--rc` is required: the `stable` channel's `omarchy` package was
still on 4.0.6 as of this writing, which predates the Pinyin
`input_method` feature this patch relies on. Check
`pacman -Q omarchy` on whatever channel you build against before
assuming a feature is present — the ISO build pipeline being current
doesn't mean the `omarchy` package it pulls is.
