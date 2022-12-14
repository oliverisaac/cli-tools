#!/usr/bin/env bash
# vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 ft=sh

set -e # Exit on any error. Use `COMMAND || true` to nullify
set -E # Functions inherit error trap
set -u # Error on unset variables. Use ${var:-alternate value} to bypass
set -f # Error on attempted file globs (e.g. *.txt )
set -o pipefail # Failed commands in pipes cause the whole pipe to fail

LOG_LEVEL=info
LOG_IN_COLOR=true
LOG_WITH_DATE=false


function open(){
    if ! [[ -t 1 ]]; then
        echo "${@:-}"
        return 0
    fi

    if which open &>/dev/null; then
        command open "${@:-}";
    elif which xdg-open &>/dev/null; then
        command xdg-open "${@:-}";
    else
        echo "open: ${@:-}"
    fi
}

function main()
{
    remote="${1:-origin}"

    urls=$( git remote | xargs -I{} git remote get-url {} )
    commit=$( git rev-parse HEAD )

    if url=$( echo "$urls" | grep dev.azure.com  | head -n 1 ); then
        # example: https://dev.azure.com/oliverisaac/example/_git/database-backups/commit/a8df13165c8bd29732afd7fd6fd4d42381914155

        read trash org project repo < <( tr '/' ' ' <<< "$url" );
        open "https://dev.azure.com/$org/$project/_git/$repo/commit/$commit"
    elif url=$( echo "$urls" | grep 'git@bitbucket.org'  | head -n 1 ); then
        # example: git@bitbucket.org:oliverisaac/example.git

        urlPath=$( echo "$url" | cut -d: -f2 | sed 's/\.git.*$//' )
        open "https://bitbucket.org/${urlPath}/commits/$commit"
    elif url=$( echo "$urls" | grep 'git@github.com'  | head -n 1 ); then
        # example: git@github.com:oliverisaac/example.git

        urlPath=$( echo "$url" | cut -d: -f2 | sed 's/\.git.*$//' )
        open "https://github.com/${urlPath}/commits/$commit"
    else
        >&2 echo "Not in an azdo backed repo: $urls"
        exit 1
    fi

    return 0
}

export LOG_LEVEL_TRACE=90 LOG_LEVEL_DEBUG=70 LOG_LEVEL_INFO=50 LOG_LEVEL_WARN=30 LOG_LEVEL_ERROR=10 LOG_LEVEL_FATAL=0
# Colors used in log lines
export LOG_COLORS=( [$LOG_LEVEL_TRACE]=37 [$LOG_LEVEL_DEBUG]=36 [$LOG_LEVEL_INFO]=32 [$LOG_LEVEL_WARN]=33 [$LOG_LEVEL_ERROR]=31 [$LOG_LEVEL_FATAL]=41)
declare -A LOG_LEVEL_MAPPING
LOG_LEVEL_MAPPING=( 
    [trace]="$LOG_LEVEL_TRACE" [debug]="$LOG_LEVEL_DEBUG" [info]="$LOG_LEVEL_INFO" [warn]="$LOG_LEVEL_WARN" [error]="$LOG_LEVEL_ERROR" [fatal]="$LOG_LEVEL_FATAL"
    [$LOG_LEVEL_TRACE]="trace" [$LOG_LEVEL_DEBUG]="debug" [$LOG_LEVEL_INFO]="info" [$LOG_LEVEL_WARN]="warn" [$LOG_LEVEL_ERROR]="error" [$LOG_LEVEL_FATAL]="fatal" 
)

function log(){
    local level="$1";
    shift 1;

    local INT_LOG_LEVEL=${LOG_LEVEL_MAPPING[$LOG_LEVEL]}
    local LEVEL_WORD=${LOG_LEVEL_MAPPING[$level]}

    # Check if we should bail
    [[ $level -le ${INT_LOG_LEVEL} ]] || return 0

    # If we are using log colors, then set those here
    local color_pre="\\e[${LOG_COLORS[$level]}m";
    local color_post='\e[0m';
    local date=""; $LOG_WITH_DATE && date=" $( date +%H:%M:%S.%3N )" || true

    {
        ${LOG_IN_COLOR} && echo -en "\\002$color_pre\\003";
        echo -n "[${LEVEL_WORD: 0:4}$date]:"
        ${LOG_IN_COLOR} && echo -en "\\002$color_post\\003";
        echo " ${@:-}"
    } >&2
}

function trace(){ log $LOG_LEVEL_TRACE "${@:-}"; }
function debug(){ log $LOG_LEVEL_DEBUG "${@:-}"; }
function info(){ log $LOG_LEVEL_INFO "${@:-}"; }
function warn(){ log $LOG_LEVEL_WARN "${@:-}"; }
function error(){ log $LOG_LEVEL_ERROR "${@:-}"; }
function fatal(){ log $LOG_LEVEL_FATAL "${@:-}"; exit 1; return 1; }

main "${@:-}"

exit $?

