#!/bin/bash

# FileVersion=1

set -eu -o pipefail -o errtrace

show_help(){
	echo "usage: $(basename "${0}"): {output} {iccfile}"
	echo "example: $(basename "${0}"): VGA-1 ${HOME}/.local/share/DisplayCAL/storage/foo/foo.icc"
	exit ${1:-0}
}

[[ $# -eq 2 ]] || show_help 1

output="${1}"
icc="${2}"

disptext="$(dispwin --help 2>&1)" || true
if ! [[ ${disptext} =~ Screen" "[0-9] ]]; then
	echo "Error: obtaining screens from dispwin"
	exit 1
fi

if ! [[ -f "${icc}" ]]; then
	echo "Error: icc file '${icc}' not readable or does not exist."
	exit 1
fi

if [[ ${disptext} =~ Screen" "[0-9]+," "Output" "${output} ]]; then
	[[ $BASH_REMATCH =~ [0-9]+ ]] && device_number=${BASH_REMATCH}
	echo $device_number
else
	echo "Error: output '${output}' not known by dispwin."
	exit 1
fi

dispwin -d${device_number} "${icc}"
