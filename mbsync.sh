#!/bin/bash

# FileVersion=5

set -euo pipefail
account="${1}" GPGKEY="${2}"
export GPGKEY
eval $(keychain --quiet --noask --agents gpg id_rsa $GPGKEY) || exit 1
mbsync "${account}"
${HOME}/bin/program-exists notmuch && grep -q "^path=${HOME}/.Mail/${account}$" "${HOME}/.notmuch-config" && notmuch new || true
