#!/bin/bash

set -euo pipefail

NODE_VERSION=""
GENERATOR_VERSION=""

while [[ $# -gt 0 ]]; do
    case ${1} in
        --node-version)
            # shellcheck disable=SC2034
            NODE_VERSION="${2}"
            shift # past argument
            shift # past value
            ;;
        --generator-version)
            # shellcheck disable=SC2034
            GENERATOR_VERSION="${2}"
            shift # past argument
            shift # past value
            ;;
        --*)
            echo "Unknown option ${1}"
            exit 1
            ;;
    esac
done

if [[ -n "${NODE_VERSION}" ]] ; then
    scripts/install-node.sh "${NODE_VERSION}"
fi

if [[ -n "${GENERATOR_VERSION}" ]] ; then
    scripts/install-generator.sh "${GENERATOR_VERSION}"
fi
