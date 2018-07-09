#!/bin/bash

# TODO:
# cercar forma de fer un make install i saber quins arxius s'han copiat, per fer un paco/porg en bash i poder emprar-lo en qualsevol distro
# ie:
#   paco amb definicions d'un programa (arxius conf per programa i/o distro)
#   generar binaris distribuibles, amb opcio d'instalar dependencies i/o llibreries necesaries per a que funcione
#   crear contenedor paco-ubuntu-16 per a la instal·lació desde zero de tots els paquets necesaris i dependencies, compilacio i creacio del tar.
#   els programes en espai d'usuari s'han de provar per veure si es poden executar desde la HOME
#   els arxius de configuració són l'únic necesari per fer tot el procés (però el contenedor és necesari per generar corrèctament la configuració)

# FileVersion=2

# paco list -a: list all packages
# paco -f <package>: list package files
# paco -r <package>: remove package

set -eu -o pipefail -o errtrace

# source /root/.bashrc; _source_utilities
# args1='[-n|--number [{number:integer}]] param1 [-c|--count] [mode1|mode2] [files...]' # for types, see check-type program
# args2='run'
# args3='list'
# arguments_list=(args1 args2 args3)
# arguments_description=('file2'
#                        'Some description.')
# arguments_parameters=( '[-n|--number [{number}]]: set number with an optional value (integer).'
#                        'param1: set param1.'
#                        '[-c|--count]: set count.'
#                        'mode1|mode2: set mode1 or mode2 (mutually exclusive).'
#                        '[files...]: optionally specify files.')
# arguments_examples=('$ file2 param1 mode1' 'some description'
#                     '$ file2 run' 'description for this one')
# arguments_extra_help=('Some extra help to show.')
# 
# argparse "$@" && shift ${arguments_shift}

#############
# Functions #
#############
show_help(){
	echo "$(basename "${0}"): manage manual packages."
	echo "  list_available: list packages available to install."
	echo "  list_installed: list installed packages."
	echo "  install <package>: install a package."
	echo "  remove <package>: remove a package."
	exit "${1:-0}"
}

get_distro(){
	if distro="$(lsb_release -i -r)"; then
		version="$(echo "${distro}" | grep "Release:" | grep -o "[0-9.]\+")"
		distro="$(echo "${distro}" | grep "Distributor ID:" | sed 's/Distributor ID:\s*//')"
		return 0
	fi
	echo "Error: unknown distro/version."
	exit 1
}

install(){
	get_distro
	local package="${1}" packagefull="${1}_${distro}${version}"
	echo "Installing ${package}/${distro}/${version}"

	if [[ -d "${package}" ]]; then
		echo "Error: folder ${package} already exists."
		exit 1
	fi

	read -p "New version string:" newversion

	if oldversion="$(paco list -a -1 | grep "${package}-")"; then
		echo "Removing old version ${oldversion}"
		paco -r ${oldversion}
	fi

	echo "New Version: ${newversion}"

	echo "Installing: ${vars[${packagefull}_required_packages]}"
	apt-get install -y ${vars[${packagefull}_required_packages]}
	echo "Installing: ${vars[${packagefull}_optional_packages]}"
	apt-get install -y ${vars[${packagefull}_optional_packages]}
	exit 0
	git clone "${vars[${packagefull}_optional_packages]}" ${package}
	cd ${package}
	${vars[${packagefull}_configure]}
	make
	paco -lp ${package}-${newversion} 'make install'
	apt-get purge -y ${vars[${packagefull}_optional_packages]}
	cd ..
	rm -I ${package}
}

#############
# Variables #
#############
declare distro version
declare -A vars=()
# Required packages: install and left installed
# Optional packages: install and remove after package installation

vars["neomutt_Ubuntu16.04_required_packages"]="gettext"
vars["neomutt_Ubuntu16.04_optional_packages"]="libncursesw5-dev libidn11-dev"
vars["neomutt_Ubuntu16.04_git"]="https://github.com/neomutt/neomutt"
vars["neomutt_Ubuntu16.04_configure"]="./configure --prefix=/usr/local"

#############
# Code      #
#############

case "${1:-}" in
	list_available) echo "neomutt" ;;
	list_installed) paco list -a -1 ;;
	install) install "${2}" ;;
	remove) paco -r "${2}" ;;
	*) show_help 0;;
esac
