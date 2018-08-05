#!/bin/bash

# FileVersion=1

set -eu -o pipefail -o errtrace

path="${1}"

for i in cur new tmp; do
	if [[ -d "${path}/${i}" ]]; then
		rm -rf "${path}/${i}"
	fi
done

mkdir -p "${path}/cur" "${path}/new" "${path}/tmp"
