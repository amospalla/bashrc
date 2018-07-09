#!/bin/bash

# FileVersion=8

set -eu -o pipefail -o errtrace

account="${1}"
hostname="$(hostname -f)"

case "${hostname}" in
	     escriptori.casa.amospalla.es) export GPGKEY=0951EEA0 ;;
	       portatil.casa.amospalla.es) export GPGKEY=2309924E ;;
	jordimarques.desktop.minorisa.net) export GPGKEY=2309924E ;;
	                                *) echo "Error: no GPGKEY defined in $(readlink -f "${0}") for hostname '${hostname}'."; exit 1 ;;
esac

lock="$(echo "${account}" | sed 's/-[^@.]*$//')"
lock="${lock//./-}"

eval $(keychain --quiet --noask --agents gpg id_rsa $GPGKEY) || exit 1
lock lock -q -f noerror mbsync-${lock} mbsync "${account}"
${HOME}/bin/program-exists -q notmuch && grep -q "^path=${HOME}/.Mail/${account}$" "${HOME}/.notmuch-config" && notmuch new || true
