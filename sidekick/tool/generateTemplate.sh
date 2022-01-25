#!/usr/bin/env bash
set -e

echo "Generating Sidekick Template Bundle"
rm -rf lib/src/templates/
mason bundle cli_template/bricks/package -t dart -o lib/src/templates/
mason bundle cli_template/bricks/entrypoint -t dart -o lib/src/templates/
mv lib/src/templates/package_bundle.dart lib/src/templates/package_bundle.g.dart
mv lib/src/templates/entrypoint_bundle.dart lib/src/templates/entrypoint_bundle.g.dart
dart format lib/src/templates/*.g.dart