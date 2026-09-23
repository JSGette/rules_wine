#!/usr/bin/env bash
#
# Usage: wine_run <windows-executable> [args...]
#
# Each invocation gets a throwaway prefix, so no state leaks between runs or
# from the user's ~/.wine.

# --- begin runfiles.bash initialization v3 ---
set -uo pipefail; set +e; f=bazel_tools/tools/bash/runfiles/runfiles.bash
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
  source "$0.runfiles/$f" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
  { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
# --- end runfiles.bash initialization v3 ---

wine="$(rlocation wine_linux_x86_64/bin/wine)"
wineserver="$(rlocation wine_linux_x86_64/bin/wineserver)"

scratch="$(mktemp -d "${TMPDIR:-/tmp}/wine_run.XXXXXX")"
cleanup() {
    "$wineserver" -k -w 2>/dev/null || true
    rm -rf "$scratch"
}
trap cleanup EXIT

export HOME="$scratch"
export XDG_CACHE_HOME="$scratch/cache"
export WINEPREFIX="$scratch/prefix"
export WINEARCH=win64
export WINESERVER="$wineserver"
export WINEDEBUG="${WINEDEBUG:--all}"
# Skip the Mono/Gecko installers and menu integration during prefix creation.
export WINEDLLOVERRIDES="mscoree,mshtml,winemenubuilder.exe="
export LANG=C.UTF-8 LC_ALL=C.UTF-8 TZ=UTC
unset DISPLAY WAYLAND_DISPLAY

"$wine" "$@"
