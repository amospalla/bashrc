#!/bin/bash

# FileVersion=11

set -eu -o pipefail -o errtrace

pgrep mutt >/dev/null || exit 0

profile="${1}" # mbsync profile name
hostname="$(hostname -f)"
account="$(echo "${profile}" | sed 's/-[^@.]*$//')" # email account
lock="${account}"
lock="${lock//./-}" # email account without dots
timeout=300

GPGKEY="$("${HOME}/bin/getgpgkey.sh")"
export GPGKEY

eval $(keychain --quiet --noask --agents gpg id_rsa $GPGKEY) || exit 1
lock lock -q -f noerror mbsync-${lock} timeout ${timeout} mbsync "${profile}"
# ${HOME}/bin/program-exists -q notmuch && grep -q "^path=${HOME}/.Mail/${profile}$" "${HOME}/.notmuch-config" && notmuch new || true
