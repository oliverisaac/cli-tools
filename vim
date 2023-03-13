#!/usr/bin/env bash

if [[ ${VIM_PATH:-} == "" ]]; then
    if ! VIM_PATH=$( which nvim 2>/dev/null ) ; then
        VIM_PATH=$( find $( find "$( brew --prefix )/Cellar" -maxdepth 1 -name '*vim*' ) \( -type d -name cli-tools \) -prune -type f  -name vim -o -name nvim -wholename '*/bin/*' | head -n 1)
        if [[ ${VIM_PATH} == "" ]]; then
            >&2 echo "You must install neovim: brew install neovim"
            exit 1
        fi
    fi
fi

tab-color cyan
"$VIM_PATH" -p "${@}"
tab-color "${TAB_COLOR:-clear}"
