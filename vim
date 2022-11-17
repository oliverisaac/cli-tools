#!/usr/bin/env bash

tab-color cyan
$(brew --prefix)/bin/vim -p --ttyfail "${@}"
tab-color clear
