#!/usr/bin/env bash

echo "Generating Sidekick Template Bundle"
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"
mason bundle ./mason/bricks/sidekick -t dart -o ./sidekick/lib/src/templates/sidekick/