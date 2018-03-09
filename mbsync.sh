#!/bin/bash

# FileVersion=3

set -euo pipefail
_error(){
	local ec=$?
	${HOME}/bin/lock unlock "${lock}"
	exit ${ec}
}

account="${1}" GPGKEY="${2}"

trap _error ERR SIGINT SIGHUP SIGTERM
declare lock
lock="mbsync-${account}"
if ${HOME}/bin/lock lock -q -f "${lock}"; then
	export GPGKEY
	eval $(keychain --noask --agents gpg id_rsa $GPGKEY)
	mbsync "${account}"
	${HOME}/bin/program-exists notmuch && grep -q "^path=${HOME}/.Mail/${account}$" "${HOME}/.notmuch-config" && notmuch new || true
	${HOME}/bin/lock unlock "${lock}"
else
	echo "Error: cound not lock '${lock}'."
	exit 1
fi
