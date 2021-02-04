#!/bin/bash

set -euo pipefail

# TODO: auth with cluster
fly -t ci login -c https://ci.concourse-ci.org/

fly -t ci teams --json > teams.json

python ./greenpeace/scripts/export-teams.py teams.json ./ci/teams/

pushd ci
	git add .
	git commit -m "update team config"
popd

