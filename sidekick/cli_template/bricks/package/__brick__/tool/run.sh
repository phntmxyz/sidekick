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

export SIDEKICK_PACKAGE_HOME=$(dirname "$TOOL_HOME")

REPO_ROOT=$(git -C "$TOOL_HOME" rev-parse --show-cdup)
export DART_VERSION="2.18.3"
DART_SDK="${SIDEKICK_PACKAGE_HOME}/build/.cache/dart-sdk"
DART="$DART_SDK/bin/dart"
CACHED_DART_SDK_VERSION=$(cat "$DART_SDK/version" 2> /dev/null) || true

# When the Dart SDK version changes or the Dart SDK is missing, install it.
if [ "$CACHED_DART_SDK_VERSION" != "$DART_VERSION" ] || [ ! -d "$DART_SDK" ]; then
  rm -rf "$DART_SDK" || true
  # Download new Dart runtime with DART_VERSION
  sh "${SIDEKICK_PACKAGE_HOME}/tool/download_dart.sh"
fi

## Run without compilation
#"${DART}" "${SIDEKICK_PACKAGE_HOME}/bin/main.dart" "$@"

HASH_PROGRAM='sha1sum'
OS="$(uname -s)"
if [[ $OS =~ Darwin.* ]]; then
  HASH_PROGRAM="shasum"
fi

STAMP_FILE="${SIDEKICK_PACKAGE_HOME}/build/cli.stamp"
HASH=$(find \
  "${SIDEKICK_PACKAGE_HOME}/bin" \
  "${SIDEKICK_PACKAGE_HOME}/lib" \
  "${SIDEKICK_PACKAGE_HOME}/tool" \
  "${SIDEKICK_PACKAGE_HOME}/pubspec.yaml" \
  "${SIDEKICK_PACKAGE_HOME}/pubspec.lock" \
  -type f -print0 | xargs -0 "$HASH_PROGRAM")
EXISTING_HASH=$(cat $STAMP_FILE 2> /dev/null) || true

EXE="${SIDEKICK_PACKAGE_HOME}/build/cli.exe"

# if exe is missing or hash has changed, rebuild
if [ ! -f "$EXE" ] || [ "$HASH" != "$EXISTING_HASH" ]; then
  # different hash, recompile
  sh "${SIDEKICK_PACKAGE_HOME}/tool/install.sh"
  echo "$HASH" > "$STAMP_FILE"
fi

"${EXE}" "$@"