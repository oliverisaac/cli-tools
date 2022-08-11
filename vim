#!/usr/bin/env bash

tab-color cyan
/usr/local/bin/vim -p --ttyfail "${@}"
tab-color clear
