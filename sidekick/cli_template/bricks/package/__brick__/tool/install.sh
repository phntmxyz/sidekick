#!/usr/bin/env bash

CWD=$PWD
CLI_PACKAGE_DIR=$(dirname "$(dirname "$0")")

cd "${CLI_PACKAGE_DIR}" || exit

  echo "Installing {{name}} command line application..."

  # export pub from .flutter dir
  REPO_ROOT=$(git rev-parse --show-cdup)
  DART_SDK="${CLI_PACKAGE_DIR}/build/cache/dart-sdk"
  DART="$DART_SDK/bin/dart" 

  # If we're on Windows, invoke the batch script instead
  OS="$(uname -s)"
  if [[ $OS =~ MINGW.* || $OS =~ CYGWIN.* ]]; then
    DART="$DART_SDK/bin/dart.exe"
  fi

  # Download Dart runtime
  if [ ! -d "$DART_SDK" ]; then
    echo 'missing flutter sdk'
    sh "${CLI_PACKAGE_DIR}/tool/install.sh"
  fi

  # build
  EXE="build/cli.exe"
  printf -- "- Getting dependencies\n"
  set -e
  "${DART}" pub get
  set +e
  printf -- "\033[1A\033[2K✔ Getting dependencies\n"
  printf -- "- Bundling assets\n"
  rm "${EXE}"
  mkdir -p build
  printf -- "\033[1A\033[2K✔ Bundling assets\n"
  printf -- "- Compiling sidekick cli\n"
  set -e
  "${DART}" compile exe -o "${EXE}" bin/main.dart
  set +e
  printf -- "\033[1A\033[2K✔ Compiling sidekick cli\n"

cd "${CWD}" || exit
