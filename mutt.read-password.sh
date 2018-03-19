#!/bin/bash

# FileVersion=2

file="${1}"

if [[ -f "${file}" ]]; then
	gpg2 -q -d "${file}"
fi
