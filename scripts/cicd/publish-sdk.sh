#!/bin/bash

set -euo pipefail

source scripts/utils.sh

setup-git enterprise

# Prepare NPM registry config
scripts/prepare-npm-config.sh

# Publish SDK
TAG="$(jq -r '.version' package.json)"
git checkout "${TAG}"

set +x
export $(grep -v '^#' npm-config.env | xargs)
set -x

npm audit --audit-level high

if [[ "$(jq -r '.version' package.json)" != "${TAG}" ]] ; then
    echo "Error: Tag that is set in 'package.json' file is different than the git tag. Please update your package with proper tags..."
    exit 1
fi 

if [[ "${NPM_REGISTRY}" != $(npm config get registry) ]] ; then
    npm publish --registry "${NPM_REGISTRY}"
else
    npm publish
fi
