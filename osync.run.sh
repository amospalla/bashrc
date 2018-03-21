#!/bin/bash

set -euo pipefail

export PATH=${PATH}:${HOME}/bin
eval $(keychain --quiet --noask --agents ssh --eval id_rsa) || exit 1
PROFILE="${1}"
. "${HOME}/.osync/${PROFILE}.conf"
"${HOME}/bin/message" send amospalla.es:55555 "sync start ${PROFILE}"

if [[ -S /tmp/osync.${PROFILE}.socket ]]; then
	rm /tmp/osync.${PROFILE}.socket
fi

socket=/tmp/osync.${PROFILE}.socket
if ! ssh ${SSH_USERHOST} -p ${SSH_PORT} -f -N -M -S ${socket} >/dev/null 2>&1; then
	echo "Error starting ssh tunnel, exit."
	[[ -S ${socket} ]] && rm ${socket}
	"${HOME}/bin/message" send amospalla.es:55555 "sync end ${PROFILE} (error starting ssh tunnel)"
	exit 0
fi

mkdir -p "${INITIATOR_SYNC_DIR}/.sync_dates"
printf "$(date +"%Y%m%d%H%M%S") $(hostname -f)" > "${INITIATOR_SYNC_DIR}/.sync_dates/$(hostname -f)"
printf "$(date +"%Y%m%d%H%M%S") ${PROFILE} $(hostname -f)" > "${HOME}/.osync/lastrun.${PROFILE}"

osync.sh "${HOME}/.osync/${PROFILE}.conf" --errors-only --summary --no-prefix && ec=$? || ec=$?

ssh ${SSH_USERHOST} -p ${SSH_PORT} -S ${socket} -O exit
"${HOME}/bin/message" send amospalla.es:55555 "sync end ${PROFILE} (${ec})"
exit $ec
