#!/usr/bin/env bash
set -e
name="{{#lowerCase}}{{name}}{{/lowerCase}}"
if ! [[ -x "$(command -v realpath)" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    brew install coreutils
  fi
fi

SCRIPT_LOCATION=$(realpath "${0%/*}/")

if [ "${SCRIPT_LOCATION}" == "/usr/local/bin" ]; then
  # When called via /usr/local/bin reverse symlink back to the project root
  THIS_SCRIPT=$(realpath "/usr/local/bin/${name}")
  ROOT=$(dirname "${THIS_SCRIPT}")
else
  # Navigate to project root, allows execution from everywhere with correct relative links
  ROOT=$SCRIPT_LOCATION
fi

CLI_PACKAGE="${ROOT}/packages/${name}_cli"
CLI_COMMITS=$(git -C "$ROOT" rev-list --count HEAD "${CLI_PACKAGE}")

EXE="${CLI_PACKAGE}/build/${name}_cli-$CLI_COMMITS.exe"

if [ ! -f "${EXE}" ]; then
  sh "${CLI_PACKAGE}/tool/install_global.sh"
fi

"${EXE}" "$@"
