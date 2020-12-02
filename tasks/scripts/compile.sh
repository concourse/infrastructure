#!/bin/bash

set -euo pipefail

output="$(pwd)/compiled/"

cd repo
go build "$PACKAGE_PATH" -o "$output"
