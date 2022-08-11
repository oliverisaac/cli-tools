#!/bin/bash

replace=$( echo "${@}" | sed -e 's/[\/&]/\\&/g' )
sed "s/^/${replace}: /"
