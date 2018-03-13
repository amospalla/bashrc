#!/bin/bash

set -euo pipefail

export PATH=${PATH}:${HOME}/bin
eval $(keychain --quiet --agents ssh --eval id_rsa)

profile="${1}"
exec osync.sh "${HOME}/.osync/${profile}.conf" --errors-only --summary --no-prefix
