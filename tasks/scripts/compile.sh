#!/bin/bash

set -euo pipefail

output="$(pwd)/compiled/"

cd repo
go build "$PATH" -o "$output"
