#!/bin/bash

# FileVersion=4

set -eu -o pipefail -o errtrace

#############
# Functions #
#############
show_help(){
	echo "$(basename "${0}"): manage manual packages."
	echo "   status:                 show available/installed status."
	echo "   install <package>:      install a package."
	echo "   remove <package>:       remove a package."
	echo "   compile-list-available: list packages available to compile."
	echo "   compile <package>:      compile a package."

	exit "${1:-0}"
}

get_package_installed(){
	local package="${1}"
	if dpkg -l "${package}" 2>/dev/null | grep -q "^ii\s"; then
		vars["${package}_installed"]="1"
	else
		vars["${package}_installed"]="0"
	fi
}

get-distro(){
	if distro="$(lsb_release -i -r)"; then
		version="$(echo "${distro}" | grep "Release:" | grep -o "[0-9.]\+")"
		distro="$(echo "${distro}" | grep "Distributor ID:" | sed 's/Distributor ID:\s*//')"
		return 0
	fi
	echo "Error: unknown distro/version."
	exit 1
}

install_packages(){
	# install_packages required $packages: install
	# install_packages dev      $packages: track if package was installed previously, if not remove after operation
	local mode="${1}" packages="${2}" package="" packages_install=""
	[[ "${#packages}" -gt 0 ]] || return 0
	for package in ${packages}; do
		get_package_installed ${package}
		if [[ ${vars["${package}_installed"]} -eq 0 ]]; then
			packages_install="${packages_install} ${package}"
		fi
	done
	[[ ${#packages_install} -eq 0 ]] || apt-get install -y ${packages_install}
}

remove_packages(){
	local packages="${1}" package="" packages_remove=""
	[[ "${#packages}" -gt 0 ]] || return 0
	for package in ${packages}; do
		if [[ ${vars["${package}_installed"]} -eq 0 ]]; then
			packages_remove="${packages_remove} ${package}"
		fi
	done
	[[ ${#packages_remove} -eq 0 ]] || apt-get purge -y ${packages_remove}
}

compile(){
	local package="${1}" packagefull="${1}_${distro}_${version}" gitopts="" taropts="" datestart="" dateend="" cmin=""
	datestart="$(printf "%(%s)T")"

	printf "Installing ${package}/${distro}/${version}:\n\n"

	if [[ -d "${package}" ]]; then
		echo "Error: folder ${package} already exists."
		exit 1
	fi

	# Install packages
	install_packages required "${vars[${packagefull}_packages_required]:-}"
	install_packages dev      "${vars[${packagefull}_packages_dev]:-}"

	# Get source code
	if [[ ${#vars[${packagefull}_git]} -gt 0 ]]; then
		[[ ${#vars[${packagefull}_git_branch]} -eq 0 ]] || gitopts="${gitopts} --branch ${vars[${packagefull}_git_branch]}"
		[[ ${vars[${packagefull}_git_recursive]:-0} -eq 0 ]] || gitopts="${gitopts} --recursive"
		git clone ${vars[${packagefull}_git]} ${gitopts} /root/${package}
	elif [[ ${#vars[${packagefull}_url]} -gt 0 ]]; then
		mkdir /root/${package}
		[[ "${vars[${packagefull}_url]}" =~ \.tar.gz ]] && taropts="z" || true
		wget "${vars[${packagefull}_url]}" -O - | tar x${taropts}pf - --strip-components 1 -C /root/${package}
	fi

	# cd path
	[[ -d ${package}/${vars[${packagefull}_configure_path]:-} ]] || mkdir -p ${package}/${vars[${packagefull}_configure_path]:-}
	cd ${package}/"${vars[${packagefull}_configure_path]:-}"

	# ./configure / cmake
	${vars[${packagefull}_configure_command]}

	# get version
	if [[ ${#vars[${packagefull}_git_branch]} -gt 0 ]]; then
		newversion=${vars[${packagefull}_git_branch]}
	else
		newversion="$(grep "^PACKAGE_VERSION=" Makefile | sed 's/^PACKAGE_VERSION=//')"
	fi
	newversion=${newversion//-}

	# make && make install
	make; make install; cd

	# generate file list/tar
	dateend="$(printf "%(%s)T")"
	# cmin=minutes elapsed up to now rounded to the upper minute
	cmin="$(( 60 - ((dateend - datestart) % 60) ))" # seconds to wait to round up to a minute
	sleep ${cmin}
	cmin="$(( (dateend - datestart + cmin) / 60 ))"
	filelist="$(find ${vars[${packagefull}_install_path]} -xdev -type f -cmin -${cmin})"
	echo ""; echo "${filelist}" | tee "${fileslist}"; echo ""
	read -p "Installed files list is on '${fileslist} file. Edit it if needed and press [Enter] key when done (hint: ctrl-z)."
	[[ -d "${filespath}" ]] || mkdir "${filespath}"
	tar zcpf "${filespath}/${package}-${newversion}-${distro}-${version}.tar.gz" $(<${fileslist})
	mv "${fileslist}" "${filespath}/${package}-${newversion}-${distro}-${version}.list"

	# remove packages and build folder
	remove_packages "${vars[${packagefull}_packages_dev]:-}"
	rm -rf "/root/${package}"
}

compile-list-available(){
	local i
	echo ${!vars[@]} | grep -Eo "(^| )[^_]+_[^_]+_[^_]+" | while read line; do
		echo "${line/_*} ($(echo ${line} | cut -d'_' -f2) $(echo ${line} | cut -d'_' -f3))"
	done | sort | uniq
}

get-online-available(){
	local nofail=${1:-0}
	if ! online_available=( $(wget -O - -q "${infourl}/info.txt" | grep "${distro}-${version}" | sed "s/-${distro}-${version}//" ) ); then
		[[ ${nofail} -eq 0 ]] || return 1
		echo "Error obtaining online info on ${infourl}/info.txt."
		exit 1
	fi
}

get-installed(){
	if [[ -d /root/.local-install ]]; then
		installed=( $(find /root/.local-install -type f | sed -e 's;/root/\.local-install/;;' -e 's/\.list$//' -e "s/-${distro}-${version}//") )
	fi
}

list-available(){
	local i
	get-online-available
	for (( i=0; i<${#online_available[@]}; i++ )); do
		echo ${online_available[$i]}
	done
	
}

get-status(){
	local package packages version_local version_remote isonline
	get-online-available 1 && isonline=1 || isonline=0
	get-installed
	if [[ ${isonline} -eq 1 ]]; then
		packages="$(for package in $(echo ${online_available[@]:-} ${installed[@]:-} | sed 's/-[^ ]*//g'); do
			echo ${package}
		done | sort | uniq)"
		for package in ${packages}; do
			unset version_local version_remote
			
			for (( i=0; i<${#online_available[@]}; i++ )); do
				if [[ ${online_available[$i]} =~ ^${package}- ]]; then
					[[ ${online_available[$i]} =~ -.* ]] && version_remote="${BASH_REMATCH/-}"
				fi
			done
			for (( i=0; i<${#installed[@]}; i++ )); do
				if [[ ${installed[$i]} =~ ^${package}- ]]; then
					[[ ${installed[$i]} =~ -.* ]] && version_local="${BASH_REMATCH/-}"
				fi
			done
			packages_status[${#packages_status[@]}]="${package}"              # package
			packages_status[${#packages_status[@]}]="${version_local:-.}"  # version local
			packages_status[${#packages_status[@]}]="${version_remote:-.}"     # version remote
			if [[ ${version_local:-none} != "none" ]]; then
				if [[ ${version_local} != ${version_remote:-${version_local}} ]]; then
					packages_status[${#packages_status[@]}]="upgradable"
				else
					packages_status[${#packages_status[@]}]="installed"
				fi
			else
				packages_status[${#packages_status[@]}]="not-installed" # upgradable
			fi
		done
	fi
}

status(){
	{	echo "package installed remote status"
		echo "------- --------------- --------------- -------------"
		for (( i=0; i<${#packages_status[@]}; i+=4 )); do
			echo "${packages_status[$i]} ${packages_status[$((i+1))]} ${packages_status[$((i+2))]} ${packages_status[$((i+3))]}"
		done
	} | column -t
}

action(){
	local action="${1}" package="${2}" stats state
	if ! stats="$(status | grep "^${package} ")"; then
		echo "Error: unknown package ${package}."; exit 1
	fi
	state="$(echo "${stats}" | awk '{print $4}')"
	if [[ ${state} == "not-installed" ]]; then
		if [[ ${action} == "install" ]]; then
			do_install ${package}
		elif [[ ${action} == "remove" ]]; then
			echo "${package} not installed."
		fi
	elif [[ ${state} == "installed" ]]; then
		if [[ ${action} == "install" ]]; then
			echo "Package already installed"
		elif [[ ${action} == "remove" ]]; then
			do_remove ${package}
		fi
	elif [[ ${state} == "upgradable" ]]; then
		if [[ ${action} == "install" ]]; then
			do_remove ${package}
			do_install ${package}
		elif [[ ${action} == "remove" ]]; then
			do_remove ${packge}
		fi
	fi
}

do_install(){
	local package="${1}" package_version
	for (( i=0; i<${#packages_status[@]}; i+=4 )); do
		if [[ ${packages_status[$i]} == "${package}" ]]; then
			package_version=${packages_status[$(( i+2))]}
		fi
	done
	wget -q "${infourl}/${package}-${package_version}-${distro}-${version}.tar.gz" -O - | tar xzpf - -C /
	[[ -d /root/.local-install ]] || mkdir -p /root/.local-install
	wget -q "${infourl}/${package}-${package_version}-${distro}-${version}.list" -O /root/.local-install/${package}-${package_version}-${distro}-${version}.list
}

do_remove(){
	local package="${1}" package_version file
	for (( i=0; i<${#packages_status[@]}; i+=4 )); do
		if [[ ${packages_status[$i]} == "${package}" ]]; then
			package_version=${packages_status[$(( i+1))]}
		fi
	done
	for file in $(</root/.local-install/${package}-${package_version}-${distro}-${version}.list); do
		if [[ -f "${file}" ]]; then
			rm "${file}"
		else
			echo "Error: file ${file} does not exist."
		fi
	done
	rm /root/.local-install/${package}-${package_version}-${distro}-${version}.list
}

#############
# Variables #
#############
declare distro version fileslist="/tmp/$(basename "${0}").filelist" filespath="/root/local-install"
declare infourl="http://www.amospalla.es/misc/local-install"
declare -A vars=() available=()
declare -a online_available=() installed=() packages_status=()

# Required packages: install and left installed
# Optional packages: install and remove after package installation
vars["neomutt_Ubuntu_16.04_packages_required"]=""
vars["neomutt_Ubuntu_16.04_packages_dev"]="build-essential git gettext xsltproc libxml2-utils docbook-xml docbook-xsl libncursesw5-dev libidn11-dev"
vars["neomutt_Ubuntu_16.04_git"]="https://github.com/neomutt/neomutt"
vars["neomutt_Ubuntu_16.04_url"]=""
vars["neomutt_Ubuntu_16.04_configure_command"]="./configure --prefix=/usr/local"
vars["neomutt_Ubuntu_16.04_configure_path"]=""
vars["neomutt_Ubuntu_16.04_git_branch"]=""
vars["neomutt_Ubuntu_16.04_git_recursive"]=""
vars["neomutt_Ubuntu_16.04_install_path"]="/usr/local"

vars["polybar_Ubuntu_16.04_packages_required"]=""
vars["polybar_Ubuntu_16.04_packages_dev"]="build-essential git cmake cmake-data pkg-config libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev python-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-cursor-dev libasound2-dev libpulse-dev i3-wm libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libiw-dev libnl-3-dev"
vars["polybar_Ubuntu_16.04_git"]="https://github.com/jaagr/polybar"
vars["polybar_Ubuntu_16.04_url"]=""
vars["polybar_Ubuntu_16.04_configure_command"]="cmake .."
vars["polybar_Ubuntu_16.04_configure_path"]="build"
vars["polybar_Ubuntu_16.04_git_branch"]="3.1.0"
vars["polybar_Ubuntu_16.04_git_recursive"]="1"
vars["polybar_Ubuntu_16.04_install_path"]="/usr/local"

vars["neomutt_Ubuntu_18.04_packages_required"]=""
vars["neomutt_Ubuntu_18.04_packages_dev"]="build-essential git gettext xsltproc libxml2-utils docbook-xml docbook-xsl libncursesw5-dev libidn11-dev"
vars["neomutt_Ubuntu_18.04_git"]="https://github.com/neomutt/neomutt"
vars["neomutt_Ubuntu_18.04_url"]=""
vars["neomutt_Ubuntu_18.04_configure_command"]="./configure --prefix=/usr/local"
vars["neomutt_Ubuntu_18.04_configure_path"]=""
vars["neomutt_Ubuntu_18.04_git_branch"]=""
vars["neomutt_Ubuntu_18.04_git_recursive"]=""
vars["neomutt_Ubuntu_18.04_install_path"]="/usr/local"

vars["polybar_Ubuntu_18.04_packages_required"]=""
vars["polybar_Ubuntu_18.04_packages_dev"]="build-essential git cmake cmake-data pkg-config libcairo2-dev libxcb1-dev libxcb-util0-dev libxcb-randr0-dev python-xcbgen xcb-proto libxcb-image0-dev libxcb-ewmh-dev libxcb-icccm4-dev libxcb-xkb-dev libxcb-cursor-dev libasound2-dev libpulse-dev i3-wm libjsoncpp-dev libmpdclient-dev libcurl4-openssl-dev libiw-dev libnl-3-dev"
vars["polybar_Ubuntu_18.04_git"]=""
vars["polybar_Ubuntu_18.04_url"]="https://github.com/jaagr/polybar/releases/download/3.1.0/polybar.tar"
vars["polybar_Ubuntu_18.04_configure_command"]="cmake .."
vars["polybar_Ubuntu_18.04_configure_path"]="build"
vars["polybar_Ubuntu_18.04_git_branch"]="3.1.0"
vars["polybar_Ubuntu_18.04_git_recursive"]=""
vars["polybar_Ubuntu_18.04_install_path"]="/usr/local"

#############
# Code      #
#############

get-distro

case "${1:-}" in
	status) get-status; status ;;
	install) get-status; action install "${2}" ;;
	remove) get-status; action remove "${2}" ;;
	compile-list-available) compile-list-available ;;
	compile) compile "${2}" ;;
	*) show_help 0;;
esac
