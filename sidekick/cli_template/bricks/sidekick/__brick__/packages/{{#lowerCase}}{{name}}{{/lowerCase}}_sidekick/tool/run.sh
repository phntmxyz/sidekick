#!/usr/bin/env bash
set -e

# Attempt to set TOOL_HOME
# Resolve links: $0 may be a link
PRG="$0"
# Need this for relative symlinks.
while [ -h "$PRG" ]; do
  ls=$(ls -ld "$PRG")
  link=$(expr "$ls" : '.*-> \(.*\)$')
  if expr "$link" : '/.*' >/dev/null; then
    PRG="$link"
  else
    PRG=$(dirname "$PRG")"/$link"
  fi
done
SAVED="$(pwd)"
cd "$(dirname "$PRG")/" >/dev/null
TOOL_HOME="$(pwd -P)"
cd "$SAVED" >/dev/null

SIDEKICK_PACKAGE_DIR=$(dirname "$TOOL_HOME")

REPO_ROOT=$(git rev-parse --show-cdup)
DART_SDK="${REPO_ROOT}.flutter/bin/cache/dart-sdk"
DART="$DART_SDK/bin/dart"

## Run without compilation
#"${DART}" "${SIDEKICK_PACKAGE_DIR}/bin/main.dart" "$@"

HASH_PROGRAM='sha1sum'
OS="$(uname -s)"
if [[ $OS =~ DARWIN.* ]]; then
  HASH_PROGRAM="shasum"
fi

STAMP_FILE="${SIDEKICK_PACKAGE_DIR}/build/cli.stamp"
HASH=$(find \
  "${SIDEKICK_PACKAGE_DIR}/bin" \
  "${SIDEKICK_PACKAGE_DIR}/lib" \
  "${SIDEKICK_PACKAGE_DIR}/tool" \
  "${SIDEKICK_PACKAGE_DIR}/pubspec.yaml" \
  "${SIDEKICK_PACKAGE_DIR}/pubspec.lock" \
  -type f -print0 | xargs -0 "$HASH_PROGRAM")
EXISTING_HASH=$(cat $STAMP_FILE) || true

if [ "$HASH" != "$EXISTING_HASH" ]; then
  # different hash, recompile
  sh "${SIDEKICK_PACKAGE_DIR}/tool/install.sh"
  echo "$HASH" > "$STAMP_FILE"
fi

EXE="${SIDEKICK_PACKAGE_DIR}/build/cli.exe"
"${EXE}" "$@"