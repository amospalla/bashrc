#!/bin/bash

# FileVersion=1

file="${1}"

if [[ -f "${file}" ]]; then
	gpg2 -q -d ~/.mutt/jordi@amospalla.es.mutt.gpg
fi
