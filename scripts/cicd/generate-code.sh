#!/bin/bash

set -xe

source scripts/utils.sh

REGENERATION_TIMESTAMP="$(date +%F_%H-%M-%S)"

# Prepare generator
if [[ -z "$JAVA_HOME" ]] ; then
    echo "JAVA_HOME environment variable could not be found..."
    exit 1
else
    export PATH=$JAVA_HOME/bin:$PATH
fi

scripts/install-generator.sh

# Download API specification file
API_SPEC_FILE="watsonx-ai.json"

if [[ ! "${API_SPEC_FROM_PARAMETER}" =~ (1|y|yes|t|true|on|run) ]] ; then
    GITHUB_TOKEN="$(get_env git-token)"
    curl -Ls \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        "https://raw.github.ibm.com/cloud-api-docs/machine-learning/master/watsonx-ai.json" \
        -o "${API_SPEC_FILE}"
fi

# Validate API specification if needed
if [[ "${VALIDATE_API_SPEC}" =~ (1|y|yes|t|true|on|run) ]] ; then
    if ! command -v lint-openapi &> /dev/null ; then
        echo "IBM-openapi-validator could not be found. Will install it now..."
        npm install -g ibm-openapi-validator
        echo "Successfully installed IBM-openapi-validator $(lint-openapi --version)"
    fi
    lint-openapi -s "${API_SPEC_FILE}" || echo "Some errors occured while validationg API specification file..."
fi

setup-git enterprise

# Switch branches
NEW_BRANCH_NAME="sdk_regeneration_${REGENERATION_TIMESTAMP}"
git checkout -b "${NEW_BRANCH_NAME}"
git push --set-upstream origin "${NEW_BRANCH_NAME}"

# Regenerate SDK
GENERATOR_DIR="./openapi-sdkgen"
"${GENERATOR_DIR}/openapi-sdkgen.sh" generate -g ibm-node -i "${API_SPEC_FILE}" -o . --genITs

# Test new code
npm run test-unit || echo "Unit tests have failed..."

# Apply eslint
npm run lint-fix

# Compare newly generated SDK code
git status
git diff

# Push to the remote repository
GENERATOR_VERSION=$("${GENERATOR_DIR}/openapi-sdkgen.sh" version)
GENERATOR_VERSION=${GENERATOR_VERSION%%-*}

git add --all
git commit -m "Code regenerated at ${REGENERATION_TIMESTAMP} - build_${BUILD_NUMBER}"
git push

# Create a draft Pull Request to the base branch
GITHUB_TOKEN="$(get_env git-token)"
GITHUB_URL="$(get_env git-url | sed 's|https://||g' | sed 's|.git||g')"
GITHUB_REPO="${GITHUB_URL#*/}"

PR_TITLE="[Pipeline] Code update - build_${BUILD_NUMBER}"
PR_BODY="**This Pull Request is created by automation pipeline.**\n\nRegenerated SDK code with openapi-sdkgen:${GENERATOR_VERSION}.\nSource API specification can be downloaded from [build URL](${BUILD_URL})\n"

PR_PAYLOAD="$(cat <<EOF
{
    "base": "${BRANCH_NAME}",
    "head": "${NEW_BRANCH_NAME}",
    "title": "${PR_TITLE}",
    "body": "${PR_BODY}",
    "draft": true
}
EOF
)"

curl -Ls \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  "https://github.ibm.com/api/v3/repos/${GITHUB_REPO}/pulls" \
  -d "${PR_PAYLOAD}"
