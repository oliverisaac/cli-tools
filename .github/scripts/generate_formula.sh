#!/usr/bin/env bash

set -eEuo pipefail # safety checks for unset variables, errors, and errors in pipes

function set_class() {
    local class_name
    class_name=$(
        echo "${1?You must pass in a class name}" |
            sed -r -e 's/^[a-z]/\U&/g; s/-[a-z]/\U&/g; s/-//g;'
    )
    echo "class ${class_name} < Formula"
}

function end() {
    echo "end"
}

function indent() {
    local num_indents=${1:-1}
    local indent_size=2 # two spaces per indent
    indent_content=$(head -c $(($num_indents * $indent_size)) /dev/zero | tr -c ' ' ' ')
    sed "s/^/$indent_content/"
}

function depends_on() {
    local dependency=${1?you must pass in a dependency}
    shift
    if [[ $dependency != :* ]]; then
        dependency="\"$dependency\""
    fi
    printf -- "%s " "depends_on" "${dependency}" "${@}" | indent 1
    echo
}

function install_binary() {
    local exe="${1?you must pass in an exe}"
    echo "bin.install \"$exe\"" | indent 2
}

function clone_from_git() {
    local repo="${1?you must pass in a git repo}"
    local tag="${2?you must pass in a release tag}"
    echo "head \"${repo}\", :using => :git" | indent
    download_url="https://${repo}/archive/refs/tags/${tag}.tar.gz"
    echo "url \"${download_url}\"" | indent
    sha=$(curl -L --fail "$download_url" | sha256sum | awk '{print $1}')
    printf 'sha256 "%s"\n' "$sha" | indent
}

function define_install() {
    echo "def install" | indent
}

function main() {
    {
        set_class "${TAP_NAME?You must pass in a name for this tap}"

        clone_from_git "${TAP_REPO?You must define the repo to be tapped}" "${RELEAST_TAG?You msut define a release tag to base your release off of}"

        echo
        while IFS= read -r -d '' dependency; do
            depends_on "$dependency"
        done < <(echo "$DEPENDENCIES" | tr ',' '\0')

        echo

        define_install
        # The find command generates a \0 on print0, so we base64 encode it temporarily
        find_output="$(find . -maxdepth 1 -perm -111 -type f -print0 | base64)"
        while IFS= read -r -d '' exe; do
            install_binary "$exe"
        done < <(echo "$find_output" | base64 -d)

        end | indent # install

        end # class

    } | tee "${OUTPUT_FILE:-${TAP_NAME}.rb}"
}

export DEFUALT_DEPENDENCIES='coreutils,:bash => "^5"'
export DEPENDENCIES="${DEPENDENCIES:-$DEFUALT_DEPENDENCIES}"
export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-oliverisaac/cli-tools}"
export BASE_REPO_NAME="${GITHUB_REPOSITORY##*/}"
export TAP_NAME="${TAP_NAME:-${BASE_REPO_NAME}}"
export TAP_REPO="${TAP_REPO:-github.com/${GITHUB_REPOSITORY:-oliverisaac/cli-tools}}"
export RELEAST_TAG="${RELEASE_TAG:-v1.0.0}"
export RELEASE_ARTIFACT="${RELEASE_ARTIFACT:-${TAP_NAME}.tar.gz}"
main "${@}"
