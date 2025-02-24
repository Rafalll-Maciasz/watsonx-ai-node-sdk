#!/bin/bash

version_comparison () {
    if [[ "$1" == "$2" ]]
    then
        echo '='
        return
    fi
    local IFS=.
    local i ver1 ver2
    read -r -a ver1 <<< "$1"
    read -r -a ver2 <<< "$2"

    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            echo '>'
            return
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            echo '<'
            return
        fi
    done
    echo '='
    return
}

function setup-git() {
    local PREFIX=""
    if [[ "${1}" == "public" ]] ; then
        PREFIX="public-"
    fi

    local GITHUB_USER
    local GITHUB_EMAIL
    local GITHUB_TOKEN
    local GITHUB_URL

    GITHUB_USER="$(get_env "${PREFIX}git-user")"
    GITHUB_EMAIL="$(get_env "${PREFIX}git-email")"
    GITHUB_TOKEN="$(get_env "${PREFIX}git-token")"
    GITHUB_URL="$(get_env "${PREFIX}git-url" | sed 's|https://||g' | sed 's|.git||g')"

    git config --local user.name "${GITHUB_USER}"
    git config --local user.email "${GITHUB_EMAIL}"
    git remote set-url origin "https://${GITHUB_USER}:${GITHUB_TOKEN}@${GITHUB_URL}.git"
    git stash
    git fetch
}
