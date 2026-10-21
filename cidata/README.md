# CC/OS autoinstall template

A tested `cidata` autoinstall drive that installs a completely stock
Omarchy ISO (no fork, no custom image) with **Chinese Pinyin input
preconfigured out of the box** — verified end-to-end in a real VM
install against `omarchy-4.5.0rc1.iso` on 2026-10-21. See `PLAN.md`
section 3 ("Chinese input preconfigured out of the box") for the full
writeup of what this does and why it works.

`cidata` is the standard cloud-init `NoCloud` convention — Omarchy's
own installer supports it natively, no patching required. Full
reference: [omarchy.org/manual/unattended-installs](https://omarchy.org/manual/unattended-installs/).

## What's here

- `user_configuration.json` — the archinstall-format config Omarchy's
  installer reads. The field that actually matters for this repo is
  `omarchy_install.input_method: "pinyin"`; everything else is a
  reasonable default (unencrypted btrfs install, UTC, `en_US.UTF-8`)
  that you'll likely want to adjust per machine — see below.

## What's *not* here (you provide these)

- `user_credentials.json` — contains the password hash, so it's not
  committed. Generate one and build it yourself:

  ```bash
  hash=$(openssl passwd -6 "your-password-here")
  cat > user_credentials.json <<EOF
  {
      "root_enc_password": "$hash",
      "users": [
          { "enc_password": "$hash", "groups": [], "sudo": true, "username": "your-username" }
      ]
  }
  EOF
  ```

## Fields you need to change before using this for real

- `disk_config.device_modifications[0].device` — `/dev/vda` is the
  virtio device name QEMU/libvirt VMs use. A real machine will have
  something like `/dev/nvme0n1` or `/dev/sda` — check with `lsblk`
  on the target first (e.g. boot the ISO once, drop to a shell).
- The partition `size` / `start` byte values are sized for a 40GB
  disk. Recompute for your actual target disk size, or just drop the
  explicit sizing and let a simpler `disk_config` shape handle it —
  the structure here mirrors what Omarchy's own CI integration tests
  use (`test/integration.d/base-test.sh` in `omacom/omarchy-iso`),
  not the only valid shape.
- `hostname`, `timezone`, `locale_config` — set these to whatever you
  actually want; the values here are placeholders.

## Building the drive

```bash
mkdir -p cidata-build && cd cidata-build
cp ../user_configuration.json ../user_credentials.json .
# optional: echo "Full Name" > user_full_name.txt
# optional: echo "false" > user_encrypt_installation.txt

truncate -s 4M cidata.img
mkfs.vfat -n CIDATA cidata.img
mcopy -i cidata.img user_configuration.json user_credentials.json ::/
```

## The one gotcha that cost real debugging time

**Attach `cidata.img` as a USB mass-storage device, not a CD-ROM.**
A FAT-formatted raw image attached as a SATA/virtual CD-ROM
(`device=cdrom` in `virt-install`, or `-device ide-cd` in raw QEMU)
fails to mount — the installer's `omarchy-cidata-load` script hits
`mount: can't read superblock`, silently gives up, and falls back to
the normal interactive wizard with no error visible on screen. You'll
just end up looking at the keyboard-layout picker, confused about why
autoinstall didn't kick in.

The fix, in `virt-install` terms:

```bash
virt-install \
  --name your-vm \
  --disk path=target-disk.qcow2,bus=virtio \
  --cdrom omarchy-4.5.0rc1.iso \
  --disk path=cidata.img,device=cdrom,bus=sata \
  ...
# then BEFORE first boot, fix the cidata attachment:
virsh detach-disk your-vm sdb --config
virsh attach-disk your-vm cidata.img sdc --targetbus usb --subdriver raw --config
```

Or in raw QEMU terms, attach it as:

```
-drive file=cidata.img,format=raw,if=none,id=cidata -device usb-storage,drive=cidata
```

This matches how Omarchy's own CI (`build_cidata` in
`test/integration.d/base-test.sh`, `omacom/omarchy-iso` repo) attaches
it — it just isn't mentioned anywhere in the user-facing manual page,
since real USB install media never has this problem (a cidata USB
stick inserted next to an ISO USB stick is already a USB device; this
gotcha is specific to emulating the whole setup in a VM).

## Verifying it worked

After first boot and login:

```bash
cat ~/.config/fcitx5/profile   # should show DefaultIM=pinyin
```

Then in any real GTK/Qt text field (not a terminal — Chromium's
address bar is a good one), press `Super+I` and type pinyin — a real
candidate window should appear (e.g. typing `nihao` shows `1.你好
2.👋 3.拟好...`).
