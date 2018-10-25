#!/bin/bash

# FileVersion=3

set -eu -o pipefail -o errtrace

show_help(){
	echo "usage: $(basename "${0}"): {output} {iccfile|folder}"
	echo ""
	echo "example: $(basename "${0}"): VGA-1 ${HOME}/.local/share/DisplayCAL/storage/foo/foo.icc"
	echo "example: $(basename "${0}"): VGA-1 ${HOME}/.local/share/DisplayCAL/storage/foo: use first icc found in folder"
	exit ${1:-0}
}

[[ $# -eq 2 ]] || show_help 1

output="${1}"
icc="${2}"

disptext="$(dispwin --help 2>&1 || true)"
if ! [[ ${disptext} =~ (Screen|Monitor)" "[0-9] ]]; then
	echo "Error: obtaining screens from dispwin"
	exit 1
fi

if ! [[ -r "${icc}" ]]; then
	echo "Error: icc file/folder '${icc}' not readable or does not exist."
	exit 1
fi

if [[ -f "${icc}" ]]; then
	true
elif [[ -d "${icc}/" ]]; then
	if icc="$(find "${icc}/" -type f -name "*.icc" | head -n1)"; then
		true
	else
		echo "Error: no icc found under folder."
	fi
fi

if [[ ${disptext} =~ (Screen|Monitor)" "[0-9]+," "Output" "${output} ]]; then
	[[ $BASH_REMATCH =~ [0-9]+ ]] && device_number=${BASH_REMATCH}
else
	echo "Error: output '${output}' not known by dispwin."
	exit 1
fi

# echo "Executing:"
# echo "dispwin -d${device_number} '${icc}'"
dispwin -d${device_number} "${icc}"
