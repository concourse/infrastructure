#!/bin/bash

set -euo pipefail

dir=${0%/*}

cd "$dir"
gsutil -m cp -r . gs://bosh-topgun-bbl-state/
