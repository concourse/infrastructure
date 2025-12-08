#!/bin/bash

set -euo pipefail

dir=${0%/*}

cd "$dir"
rm -rf bosh-topgun-bbl-state
gsutil -m cp -r gs://bosh-topgun-bbl-state/ .
