#!/usr/bin/env bash
set -e

CWD=$PWD
CLI_PACKAGE_DIR=$(dirname "$(dirname "$0")")

# Writes a line to stderr
echoerr() { printf -- "$@\n" 1>&2; }

# Writes to stderr
printerr() { printf -- "$@" 1>&2; }

# removes current line from console
deleteLine() { printerr "\033[1A\033[2K"; }

# Runs command and only prints stdout and stderr if it fails
runSilent() {
  set +e
  output=$("$@" 2>&1)
  local EXIT_CODE=$?;
  if [ $EXIT_CODE -ne 0 ]; then
    echoerr "$output"
  fi
  set -e
  return $EXIT_CODE
}

cd "${CLI_PACKAGE_DIR}" || exit
  echoerr "Installing sk command line application..."

  # Find dart executable from embedded dart sdk
  DART_SDK="${CLI_PACKAGE_DIR}/build/cache/dart-sdk"
  DART="$DART_SDK/bin/dart"

  # If we're on Windows, invoke the batch script instead
  OS="$(uname -s)"
  if [[ $OS =~ MINGW.* || $OS =~ CYGWIN.* ]]; then
    DART="$DART_SDK/bin/dart.exe"
  fi

  # Build the cli
  EXE="build/cli.exe"

  echoerr "- Getting dependencies"
  runSilent "${DART}" pub get
  deleteLine
  echoerr "✔ Getting dependencies"

  echoerr "- Bundling assets"
  rm -f "${EXE}"
  mkdir -p build
  deleteLine
  echoerr "✔ Bundling assets"

  echoerr "- Compiling sidekick cli"
  if runSilent "${DART}" compile exe -o "${EXE}" bin/main.dart; then
    deleteLine
    echoerr "✔ Compiling sidekick cli"
  else
    echoerr "Compilation failed. Trying dart pub upgrade"
    LOCK_FILE=$(cat pubspec.lock)
    runSilent "${DART}" pub upgrade
    echoerr "- Compiling sidekick cli with updated dependencies"
    if runSilent "${DART}" compile exe -o "${EXE}" bin/main.dart; then
      deleteLine
      echoerr "✔ Compiling sidekick cli with updated dependencies"
    else
      echoerr "Compilation with updated dependencies failed, too. Restoring pubspec.lock"
      echo "$LOCK_FILE" > pubspec.lock
      exit 1
    fi
  fi
  echoerr "🎉Success!\n"

cd "${CWD}" || exit

