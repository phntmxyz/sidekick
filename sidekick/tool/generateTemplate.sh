#!/usr/bin/env bash
set -e

echo "Generating Sidekick Template Bundle"
mason bundle cli_template/bricks/sidekick -t dart -o lib/src/templates/
mv lib/src/templates/sidekick_bundle.dart lib/src/templates/cli_bundle.g.dart
dart format lib/src/templates/cli_bundle.g.dart