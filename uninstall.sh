#!/bin/bash
# Undo install.sh. Picks the version for this system, same as install.sh does;
# set CC_OS_TARGET=omarchy or CC_OS_TARGET=ubuntu to choose one yourself.
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
  omarchy|ubuntu) exec "$repo/$target/uninstall.sh" "$@" ;;
  *) echo "Set CC_OS_TARGET=omarchy or CC_OS_TARGET=ubuntu." >&2; exit 1 ;;
esac
