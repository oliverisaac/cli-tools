#!/usr/bin/env bash

set -euo pipefail # safety checks for unset variables, errors, and errors in pipes

export indent="  "

function set_class() {
    local class_name
    class_name=$(
        echo "${1?You must pass in a class name}" |
            sed -r -e 's/^[a-z]/\U&/g; s/-[a-z]/\U&/g; s/-//g;'
    )
    echo "class ${class_name} < Formula"
}

function end_class() {
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
    echo "bin.install \"$exe\"" | indent 1
}

function clone_from_git() {
    local repo="${1?you must pass in a git repo}"
    echo "head \"${repo}\", :using => :git" | indent
}

function main() {
    {
        set_class "${TAP_NAME?You must pass in a name for this tap}"

        clone_from_git "${TAP_REPO?You must define the repo to be tapped}"

        depends_on "coreutils"
        depends_on "oliverisaac/koi"
        depends_on ':bash = >"5"'

        while IFS= read -r -d '' exe; do
            install_binary "$exe"
        done < <(find . -maxdepth 1 -perm +111 -type f -print0)

        end_class
    } | tee "${OUTPUT_FILE:-${TAP_NAME}.rb}"
}

export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-oliverisaac/cli-tools}"
export BASE_REPO_NAME="${GITHUB_REPOSITORY##*/}"
export TAP_NAME="${TAP_NAME:-${BASE_REPO_NAME}}"
export TAP_REPO="${TAP_REPO:-github.com/${GITHUB_REPOSITORY:-oliverisaac/cli-tools}}"
main "${@}"
