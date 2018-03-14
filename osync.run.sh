#!/bin/bash

set -euo pipefail

export PATH=${PATH}:${HOME}/bin
eval $(keychain --quiet --noask --agents ssh --eval id_rsa) || exit 1

profile="${1}"
exec osync.sh "${HOME}/.osync/${profile}.conf" --errors-only --summary --no-prefix
