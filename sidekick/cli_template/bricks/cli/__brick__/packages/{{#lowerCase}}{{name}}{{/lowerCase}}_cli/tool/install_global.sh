#!/usr/bin/env bash

CWD=$PWD
CLI_PACKAGE_DIR=$(dirname "$(dirname "$0")")
name="{{#lowerCase}}{{name}}{{/lowerCase}}"

cd "${CLI_PACKAGE_DIR}" || exit

  echo "Installing $name command line application..."

  # export pub from .flutter dir
  REPO_ROOT=$(git rev-parse --show-cdup)
  DART_SDK="${REPO_ROOT}.flutter/bin/cache/dart-sdk"
  PUB="$DART_SDK/bin/pub"
  DART="$DART_SDK/bin/dart"

  if [ ! -d "$DART_SDK" ]; then
    echo 'missing flutter sdk'
    sh "${REPO_ROOT}flutterw"
  fi

  # build
  printf -- "- Getting dependencies\n"
  $PUB get >/dev/null 2>&1
  printf -- "\033[1A\033[2K✔ Getting dependencies\n"
  printf -- "- Bundling assets\n"
  rm -rf build
  mkdir -p build
  printf -- "\033[1A\033[2K✔ Bundling assets\n"
  printf -- "- Compiling $name cli\n"
  CLI_COMMITS=$(git rev-list --count HEAD .)
  EXE="build/${name}_cli-${CLI_COMMITS}.exe"
  $DART compile exe -o "${EXE}" bin/${name}.dart >/dev/null 2>&1
  printf -- "\033[1A\033[2K✔ Compiling $name cli\n"


  if [ ! -f "/usr/local/bin/$name" ] ; then
    # when not linked globally
    if [ -t 0 ] ; then
      # stdin exits, human ist interacting with script
      read -p "Do you want to install the $name cli globally? (y/n) " x
      if [ "$x" = "y" ] ; then
        sudo rm /usr/local/bin/$name > /dev/null 2>&1 || true
        SH="$(realpath "${REPO_ROOT}${name}")"
        sudo ln -s "${SH}" /usr/local/bin/$name
        echo ""
        echo "You can now use '$name' from everywhere"
        echo ""
      fi
    fi
  fi

cd "${CWD}" || exit
