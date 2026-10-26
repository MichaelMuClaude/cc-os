#!/bin/bash
# CC/OS post-install. Picks the version for this system and hands over to it:
#   omarchy/install.sh   Omarchy (Arch Linux, Hyprland)
#   ubuntu/install.sh    Ubuntu and other Debian-based systems running GNOME
# Set CC_OS_TARGET=omarchy or CC_OS_TARGET=ubuntu to choose one yourself.
# All options are passed on; run it with --help to see them.
set -euo pipefail

repo="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

target="${CC_OS_TARGET:-}"
if [[ -z $target ]]; then
  id="" id_like=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    id="${ID:-}" id_like="${ID_LIKE:-}"
  fi
  case " $id $id_like " in
    *" omarchy "*) target=omarchy ;;
    *" ubuntu "*|*" debian "*) target=ubuntu ;;
    *" arch "*)
      command -v omarchy >/dev/null 2>&1 && target=omarchy ;;
  esac
fi

case $target in
  omarchy|ubuntu) exec "$repo/$target/install.sh" "$@" ;;
  *)
    echo "CC/OS supports Omarchy (Arch) and Ubuntu / Debian with GNOME; this system is '${target:-${id:-unknown}}'." >&2
    echo "Set CC_OS_TARGET=omarchy or CC_OS_TARGET=ubuntu to force one." >&2
    exit 1 ;;
esac
