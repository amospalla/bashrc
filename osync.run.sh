#!/bin/bash

set -euo pipefail

export PATH=${PATH}:${HOME}/bin
eval $(keychain --quiet --noask --agents ssh --eval id_rsa) || exit 1
profile="${1}"

socket=/tmp/osync.${profile}.socket
if ! ssh jordi@backup2.amospalla.es -f -N -M -S ${socket} >/dev/null 2>&1; then
	echo "Error starting ssh tunnel, exit."
	rm $temp
	exit 1
fi

. "${HOME}/.osync/${profile}.conf"
mkdir -p "${INITIATOR_SYNC_DIR}/.sync_dates"
printf "$(date +"%Y%m%d%H%M%S") $(hostname -f)" > "${INITIATOR_SYNC_DIR}/.sync_dates/$(hostname -f)"
printf "${profile} $(date +"%Y%m%d%H%M%S") $(hostname -f)" > "${HOME}/.osync/lastrun.${profile}"

osync.sh "${HOME}/.osync/${profile}.conf" --errors-only --summary --no-prefix

ssh jordi@backup2.amospalla.es -S ${socket} -O exit
