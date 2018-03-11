#!/bin/bash

# FileVersion=4

set -euo pipefail
account="${1}" GPGKEY="${2}"
export GPGKEY
eval $(keychain --noask --agents gpg id_rsa $GPGKEY)
mbsync "${account}"
${HOME}/bin/program-exists notmuch && grep -q "^path=${HOME}/.Mail/${account}$" "${HOME}/.notmuch-config" && notmuch new || true
