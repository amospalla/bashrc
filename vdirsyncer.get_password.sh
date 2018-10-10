#!/bin/bash

# FileVersion=1

export GPGKEY="$("${HOME}/bin/getgpgkey.sh")"

eval $(keychain --quiet --noask --agents gpg id_rsa $GPGKEY) || exit 1
gpg2 -q -d "${HOME}/.vdirsyncer/password.gpg"
