#!/bin/bash
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/ipagrab-test.XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT
export IPAGRAB_CACHE="$TMP/cache with space" IPAGRAB_DEST="$TMP/dest with space" IPAGRAB_SOURCE_ONLY=1 NO_COLOR=1
mkdir -p "$IPAGRAB_CACHE" "$IPAGRAB_DEST" "$TMP/fixture/Payload"
. "$ROOT/ipagrab"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
assert_file() { [ -f "$1" ] || fail "missing file: $1"; }
assert_count() {
  local expected=$1 dir=$2 actual
  actual=$(find "$dir" -type f ! -name '.ipagrab.*' | wc -l | tr -d ' ')
  [ "$actual" = "$expected" ] || fail "expected $expected output file(s), found $actual"
}
make_ipa() {
  local out=$1
  printf 'test payload\n' > "$TMP/fixture/Payload/app"
  (cd "$TMP/fixture" && zip -qr "$out" Payload) || fail "could not create test IPA"
}

validate_paths || fail "temporary cache and destination failed preflight"
[ "$(human_size 1536)" = "1.5 KiB" ] || fail "human-readable size is incorrect"
PLAIN_SCREEN=$(show_banner; show_setup; state_line "READY" "test")
ESC=$(printf '\033')
case "$PLAIN_SCREEN" in *"$ESC"*) fail "NO_COLOR screen contains ANSI styling";; esac
case "$PLAIN_SCREEN" in *"Watch: $IPAGRAB_CACHE"*"Save:  $IPAGRAB_DEST"*) ;; *) fail "first screen omits configured paths";; esac
REAL_CACHE=$CACHE
CACHE="$TMP/missing-cache"
PREFLIGHT_ERROR=$(validate_paths 2>&1) && fail "missing cache passed preflight"
case "$PREFLIGHT_ERROR" in *'cache does not exist'*) ;; *) fail "missing cache error was unclear";; esac
CACHE=$REAL_CACHE
CACHE='-relative-cache'
PREFLIGHT_ERROR=$(validate_paths 2>&1) && fail "relative cache path passed preflight"
case "$PREFLIGHT_ERROR" in *'cache path must be absolute'*) ;; *) fail "relative cache error was unclear";; esac
CACHE=$REAL_CACHE

REAL_DEFAULT_CACHE=$DEFAULT_CACHE
REAL_CONFIGURATOR_HOME=$CONFIGURATOR_HOME
FUTURE_CACHE="$TMP/future-cache"
FUTURE_HOME="$TMP/configurator-home"
mkdir "$FUTURE_HOME"
CACHE=$FUTURE_CACHE; DEFAULT_CACHE=$FUTURE_CACHE; CONFIGURATOR_HOME=$FUTURE_HOME
validate_paths || fail "missing default cache should be allowed while Configurator home exists"
find_candidate >/dev/null 2>&1; CANDIDATE_STATUS=$?
[ "$CANDIDATE_STATUS" = 3 ] || fail "missing default cache did not enter waiting state"
mkdir "$FUTURE_CACHE"
find_candidate >/dev/null 2>&1; CANDIDATE_STATUS=$?
[ "$CANDIDATE_STATUS" = 1 ] || fail "newly created empty cache was not scanned"
CACHE=$REAL_CACHE; DEFAULT_CACHE=$REAL_DEFAULT_CACHE; CONFIGURATOR_HOME=$REAL_CONFIGURATOR_HOME

make_ipa "$IPAGRAB_CACHE/stale.ipa"
snapshot_cache
[ -z "$(find_candidate)" ] || fail "stale IPA was selected"

printf 'not a zip\n' > "$IPAGRAB_CACHE/partial.ipa"
[ "$(find_candidate)" = "$IPAGRAB_CACHE/partial.ipa" ] || fail "new invalid IPA was not selected for validation"
copy_complete_ipa "$IPAGRAB_CACHE/partial.ipa" && fail "invalid IPA was copied"
reject_candidate "$IPAGRAB_CACHE/partial.ipa"
assert_count 0 "$IPAGRAB_DEST"

printf 'still growing\n' >> "$IPAGRAB_CACHE/partial.ipa"
LAST_CANDIDATE="$IPAGRAB_CACHE/partial.ipa"
make_ipa "$IPAGRAB_CACHE/complete.ipa"
[ "$(find_candidate)" = "$IPAGRAB_CACHE/complete.ipa" ] || fail "growing invalid IPA starved a later valid candidate"
copy_complete_ipa "$IPAGRAB_CACHE/complete.ipa" || fail "complete IPA was not copied"
[ -z "$COPY_TMP" ] || fail "successful copy left temporary state"
assert_count 1 "$IPAGRAB_DEST"
assert_file "$RESULT"
unzip -tqq "$RESULT" || fail "copied IPA is not a readable ZIP"

LAST_CANDIDATE="$IPAGRAB_CACHE/complete.ipa"
[ "$(find_candidate)" = "$IPAGRAB_CACHE/partial.ipa" ] || fail "changed rejected IPA was not reconsidered"
reject_candidate "$IPAGRAB_CACHE/partial.ipa"
assert_count 1 "$IPAGRAB_DEST"

rm -f "$IPAGRAB_DEST"/*
make_ipa "$IPAGRAB_CACHE/collision.ipa"
date() { printf '120000\n'; }
printf 'keep me\n' > "$IPAGRAB_DEST/120000_collision.ipa"
copy_complete_ipa "$IPAGRAB_CACHE/collision.ipa" || fail "collision copy failed"
[ "$(cat "$IPAGRAB_DEST/120000_collision.ipa")" = "keep me" ] || fail "existing destination was overwritten"
assert_file "$IPAGRAB_DEST/120000_collision_1.ipa"
unzip -tqq "$IPAGRAB_DEST/120000_collision_1.ipa" || fail "collision copy is not a readable ZIP"

HELP=$(
  unset IPAGRAB_SOURCE_ONLY
  "$ROOT/ipagrab" --help
) || fail "--help failed"
case "$HELP" in *'Usage: ipagrab [--help]'*) ;; *) fail "--help output is missing usage";; esac
case "$HELP" in *"$ESC"*) fail "NO_COLOR help contains ANSI styling";; esac
(
  unset IPAGRAB_SOURCE_ONLY
  "$ROOT/ipagrab" --help extra >/dev/null 2>&1
) && fail "ipagrab accepted extra arguments"

NONINTERACTIVE=$(
  unset IPAGRAB_SOURCE_ONLY
  "$ROOT/ipagrab" </dev/null 2>&1
)
NONINTERACTIVE_STATUS=$?
[ "$NONINTERACTIVE_STATUS" -ne 0 ] || fail "non-interactive run unexpectedly succeeded"
case "$NONINTERACTIVE" in *'interactive terminal is required'*'Next:'*) ;; *) fail "non-interactive error lacks a next step";; esac
case "$NONINTERACTIVE" in *"$ESC"*) fail "non-interactive error contains ANSI styling";; esac

uname() { printf 'Linux\n'; }
PREFLIGHT_ERROR=$(preflight 2>&1) && fail "unsupported platform passed preflight"
case "$PREFLIGHT_ERROR" in *'macOS is required'*) ;; *) fail "unsupported platform error was unclear";; esac
unset -f uname

command() {
  if [ "$1" = "-v" ] && [ "$2" = "unzip" ]; then return 1; fi
  builtin command "$@"
}
PREFLIGHT_ERROR=$(preflight 2>&1) && fail "missing command passed preflight"
case "$PREFLIGHT_ERROR" in *'required command not found: unzip'*) ;; *) fail "missing command error was unclear";; esac
unset -f command

INSTALL_HOME="$TMP/install-home"
INSTALL_BIN="$INSTALL_HOME/bin"
INSTALL_TARGET="$INSTALL_BIN/ipagrab"
INSTALL_PATH="$INSTALL_BIN:/usr/bin:/bin"
mkdir -p "$INSTALL_BIN" "$INSTALL_HOME/.local/bin"
run_install() { HOME="$INSTALL_HOME" PATH="$INSTALL_PATH" /bin/bash "$ROOT/install.sh" "$@"; }

printf 'keep me\n' > "$INSTALL_TARGET"
run_install >/dev/null 2>&1 && fail "installer overwrote an unrelated file"
[ "$(cat "$INSTALL_TARGET")" = "keep me" ] || fail "installer changed an unrelated file"
rm -f "$INSTALL_TARGET"

ln -s "$TMP/unrelated" "$INSTALL_TARGET"
run_install >/dev/null 2>&1 && fail "installer overwrote an unrelated symlink"
[ "$(readlink "$INSTALL_TARGET")" = "$TMP/unrelated" ] || fail "installer changed an unrelated symlink"
run_install uninstall >/dev/null || fail "uninstall failed with an unrelated symlink"
[ -L "$INSTALL_TARGET" ] || fail "uninstall removed an unrelated symlink"
rm -f "$INSTALL_TARGET"

run_install >/dev/null || fail "install failed"
[ "$(readlink "$INSTALL_TARGET")" = "$ROOT/ipagrab" ] || fail "install created the wrong symlink"
run_install >/dev/null || fail "repeat install failed"
run_install uninstall extra >/dev/null 2>&1 && fail "uninstall accepted extra arguments"
[ "$(readlink "$INSTALL_TARGET")" = "$ROOT/ipagrab" ] || fail "invalid uninstall changed the managed symlink"
ln -s "$TMP/unrelated" "$INSTALL_HOME/.local/bin/ipagrab"
run_install uninstall >/dev/null || fail "uninstall failed"
[ ! -e "$INSTALL_TARGET" ] && [ ! -L "$INSTALL_TARGET" ] || fail "uninstall left its managed symlink"
[ -L "$INSTALL_HOME/.local/bin/ipagrab" ] || fail "uninstall removed an unrelated symlink"
run_install uninstall >/dev/null || fail "repeat uninstall failed"

printf 'PASS: grabbing, installation, and terminal output\n'
