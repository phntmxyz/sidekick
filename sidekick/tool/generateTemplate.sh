#!/usr/bin/env bash

echo "Generating Sidekick Template Bundle"
mason bundle cli_template/bricks/cli -t dart -o lib/src/templates/
mv lib/src/templates/cli_bundle.dart lib/src/templates/cli_bundle.g.dart