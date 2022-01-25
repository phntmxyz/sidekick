#!/usr/bin/env bash
set -e

# Attempt to set ENTRYPOINT_HOME
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
export SIDEKICK_ENTRYPOINT_HOME="$(pwd -P)"
cd "$SAVED" >/dev/null

{{{packagePath}}}/tool/run.sh "$@"