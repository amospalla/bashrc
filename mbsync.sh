#!/bin/bash

# FileVersion=9

set -eu -o pipefail -o errtrace

pgrep mutt >/dev/null || exit 0

profile="${1}" # mbsync profile name
hostname="$(hostname -f)"

case "${hostname}" in
	     escriptori.casa.amospalla.es) export GPGKEY=0951EEA0 ;;
	       portatil.casa.amospalla.es) export GPGKEY=2309924E ;;
	jordimarques.desktop.minorisa.net) export GPGKEY=2309924E ;;
	                                *) echo "Error: no GPGKEY defined in $(readlink -f "${0}") for hostname '${hostname}'."; exit 1 ;;
esac

account="$(echo "${profile}" | sed 's/-[^@.]*$//')" # email account
lock="${account}"
lock="${lock//./-}" # email account without dots

eval $(keychain --quiet --noask --agents gpg id_rsa $GPGKEY) || exit 1
lock lock -q -f noerror mbsync-${lock} mbsync "${profile}"
# ${HOME}/bin/program-exists -q notmuch && grep -q "^path=${HOME}/.Mail/${profile}$" "${HOME}/.notmuch-config" && notmuch new || true
