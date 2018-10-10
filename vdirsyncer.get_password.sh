#!/bin/bash

# FileVersion=2

# read -s -p password: pass && echo ${pass} | gpg2 -r jordi@amospalla.es -e > ~/.vdirsyncer/password.gpg

export GPGKEY="$("${HOME}/bin/getgpgkey.sh")"

eval $(keychain --quiet --noask --agents gpg id_rsa $GPGKEY) || exit 1
gpg2 -q -d "${HOME}/.vdirsyncer/password.gpg"
