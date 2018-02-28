#!/bin/bash

# FileVersion=470
FileVersion=470

#====================================================================
# Main
#====================================================================

# argparse
declare -A arguments=() _perf_data=() _binary
declare -a arguments_list=() arguments_description=() arguments_examples=() arguments_extra_help=() arguments_parameters=()
declare -i arguments_shift ps1_bash_update=0 _bash_updated=0

_ip_regex="(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\."
_ip_regex="${_ip_regex}(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\."
_ip_regex="${_ip_regex}(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\."
_ip_regex="${_ip_regex}(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])(/([0-9]|1[0-9]|2[0-9]|3[012]))?"

_main(){
	export LC_MESSAGES=C LC_NUMERIC=C
	[[ -x "${HOME}/.bashrc" ]] || chmod u+x "${HOME}/.bashrc"

	if [[ $- != *i* ]] ; then
		export bashrc_interactive=0
		_source_path_add_home_bin
		_program_load "$@" # Check if ${0} is this .bashrc or a link to it and execute the program asked for and exit, else we return.
		# Shell is non-interactive.  Be done now!
		return
	else
		_source_path_add_home_bin
		_source_bash_options
		_source_variables
		_source_dir_stack
		_source_histgrep
		_source_ps1
		_source_variables_amospalla
		_source_aliases_amospalla
		export bashrc_interactive=1
		[[ "${_update_enable:-0}" -eq 1 ]] && ( _bash_update bashrc  & ) || true
		_binary_decode
	fi
}

#====================================================================
# Variables
#====================================================================

_source_variables(){
	# If system doesn't have terminfo for me, use a generic TERM like linux
	[[ "$(tput cols 2>&1)" =~ 'unknown terminal' ]] && export TERM=linux || true
	export PS4='DEBUG: ${0/*\/}:$( printf "%$(( 4 - ${#LINENO} ))s" "" )${LINENO}: ' # Pretty debug
	
	! shopt -oq posix && _source "/etc/profile.d/bash-completion"
	! shopt -oq posix && _source "/etc/profile.d/bash-completion.sh"
	! shopt -oq posix && _source "/etc/bash-completion"
	
	_source "${HOME}/.bashrc2"
	_source "${HOME}/.bashrc.local"
}

_source_variables_amospalla(){
	export GIT_EDITOR=vim
	[[ "$OSTYPE" == cygwin ]] && \
		[[ -f /cygdrive/c/Windows/system32/PING.EXE ]] && \
		alias ping=/cygdrive/c/Windows/system32/PING.EXE
}

#====================================================================
# Functions
#====================================================================

perf_start(){
	[[ $# -eq 0 || "${1}" =~ "-h|--help" ]] && printf "Usage: perf_start {id}}\n" && return 0
	_perf_data[${1}]=$(($(date +%s%N)/1000))
}

perf_end(){
	[[ $# -eq 0 || "${1}" =~ "-h|--help" ]] && printf "Usage: perf_end {id}}\n" && return 0
	local diff=$(( $(date +%s%N)/1000 - ${_perf_data[${1}]} ))
	local overhead=$(( -1 * ($(date +%s%N)/1000 - $(date +%s%N)/1000) ))
	echo "$(( ${diff} - ${overhead} ))"
}

file-readable(){
	[[ $# -eq 0 || "${1}" =~ "-h|--help" ]] && printf "Usage: [-m|--message] [-i|--invert] file-readable {files...}\n" && return 0
	[[ "${1}" == "^(-m|--message)$" ]] && local message=1 && shift || local message=0
	[[ "${1}" =~ ^(-i|--invert)$  ]] && local invert=1 && shift  || local invert=0
	[[ $# -eq 0 ]] && echo "Error: no input supplied." && exit 1
	while [[ $# -gt 0 ]]; do
		if [[ -r "${1}" && ${invert} -eq 1 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: file '$1' is readable."; return 1
		elif [[ ! -r "${1}" && ${invert} -eq 0 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: file '$1' is not readable or does not exist."; return 1
		fi
		shift
	done
}

folder-exists(){
	[[ $# -eq 0 || "${1}" =~ "-h|--help" ]] && printf "Usage: folder-exists [-m|--message] [-i|--invert] {folders...}\n" && return 0
	[[ "${1}" =~ ^(-m|--message)$ ]] && local message=1 && shift || local message=0
	[[ "${1}" =~ ^(-i|--invert)$  ]] && local invert=1 && shift  || local invert=0
	[[ $# -eq 0 ]] && echo "Error: no input supplied." && exit 1
	while [[ $# -gt 0 ]]; do
		if [[ -d "${1}" && ${invert} -eq 1 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: folder '$1' exists."; return 1
		fi
		if [[ ! -d "${1}" && ${invert} -eq 0 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: '$1' does not exist or is not a folder."; return 1
		fi
		shift
	done
}

folder-writable(){
	[[ $# -eq 0 || "${1}" =~ "-h|--help" ]] && printf "Usage: folder-writable [-m|--message] [-i|--invert] {folders...}\n" && return 0
	[[ "${1}" =~ ^(-m|--message)$ ]] && local message=1 && shift || local message=0
	[[ "${1}" =~ ^(-i|--invert)$  ]] && local invert=1 && shift  || local invert=0
	[[ $# -eq 0 ]] && echo "Error: no input supplied." && exit 1
	while [[ $# -gt 0 ]]; do
		if [[ -w "${1}" && ${invert} -eq 1 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: folder ${1} is writable."; return 1
		elif [[ ! -w "${1}" && ${invert} -eq 0 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: folder ${1} is not writable."; return 1
		fi
		shift
	done
}

is-number(){
	[[ $# -eq 0 || "${1}" =~ "-h|--help" ]] && printf "Usage: is-number [-m|--message] [-i|--invert] {string}\n" && return 0
	[[ "${1}" =~ ^(-m|--message)$ ]] && local message=1 && shift || local message=0
	[[ "${1}" =~ ^(-i|--invert)$  ]] && local invert=1 && shift  || local invert=0
	[[ $# -eq 0 ]] && echo "Error: no input supplied." && exit 1
	echo $@ | grep -q "^[0-9]\+$" && is_number=1 || is_number=0
	if [[ ${is_number} -eq 1 && ${invert} -eq 1 ]]; then
		[[ ${message} -eq 1 ]] && echo "Error: '${1}' is a number."; return 1
	elif [[ ${is_number} -eq 0 && ${invert} -eq 0 ]]; then
		[[ ${message} -eq 1 ]] && echo "Error: '${1}' is not a number."; return 1
	fi
}

program-exists(){
	[[ $# -eq 0 || "${1}" =~ "-h|--help" ]] && printf "Usage: program-exists [-m|--message] [-i|--invert] {programs...}\n" && return 0
	[[ "${1}" =~ ^(-m|--message)$ ]] && local message=1 && shift || local message=0
	[[ "${1}" =~ ^(-i|--invert)$  ]] && local invert=1 && shift  || local invert=0
	[[ $# -eq 0 ]] && echo "Error: no input supplied." && exit 1
	while [[ $# -gt 0 ]]; do
		which "${1:-__None__}" >/dev/null 2>&1 && local exists=1 || local exists=0
		if [[ ${exists} -eq 1 && ${invert} -eq 1 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: program ${1} is available."; return 1
		elif [[ ${exists} -eq 0 && ${invert} -eq 0 ]]; then
			[[ ${message} -eq 1 ]] && echo "Error: program ${1} is not available."; return 1
		fi
		shift
	done
}

lowercase(){ echo "${1,,}"; }

uppercase(){ echo "${1^^}"; }

trim(){ echo "${1}" | sed -e 's/^[[:space:]]\+//g' -e  's/[[:space:]]\+$//g'; }

vimode(){
	set -o vi
	bind '"\C-i":complete'
	bind -m vi-insert "\C-i":complete
	# ^p check for partial match in history
	bind -m vi-insert "\C-p":dynamic-complete-history
	# ^n cycle through the list of partial matches
	bind -m vi-insert "\C-n":menu-complete
	# ^l clear screen in bash vi mode
	bind -m vi-insert "\C-l":clear-screen
}

_source(){
	[[ -r "${1:-}" ]] && . "${1}" || true
}

_bash_update(){
	[[ $# -eq 0 ]] && return 0
	local name="${1:-}"
	local filepath="${HOME}/.${name}"
	local url="${_update_url}/${name}"
	
	file-readable "${filepath}" || return
	
	local bashrc_online="$(wget --timeout=10 ${url} -O - 2> /dev/null)"
	local onlineversion="$(echo "${bashrc_online}" | grep -m1 "^# FileVersion=")"
	onlineversion="${onlineversion//# FileVersion=/}"
	[[ ${onlineversion} =~ ^[0-9]+$ ]] || return
	is-number ${onlineversion} || return
	if [[ ${FileVersion} -lt ${onlineversion} ]]; then
		echo "${bashrc_online}" > "${filepath}"
		echo "${FileVersion} > ${onlineversion}" > "/tmp/${UID}.$$.bashrcupdate"
	fi
}

_source_path_add_home_bin(){
	[[ -d ${HOME}/bin ]] || mkdir ${HOME}/bin
	[[ ! "${PATH}" =~ ${HOME}/bin(:|$) ]] && export PATH="${PATH}:$HOME/bin" || true
}

_source_dir_stack(){
	cd() {
		local MAX=10
		local LEN=${#DIRSTACK[@]}
		local p
		
		if [[ $# -eq 0 ]] || [[ "$1" = "-" ]]; then
			builtin cd "$@"
			pushd -n $OLDPWD > /dev/null
		else
			pushd "$@" > /dev/null || return 1
		fi
		
		if [[ $LEN -gt 1 ]]; then
			for i in `seq 1 $LEN`; do
				eval p=~$i
				if [[ "$p" = "$PWD" ]]; then
					popd -n +$i > /dev/null
					break
				fi
			done
		fi
		
		if [[ $LEN -ge $MAX ]]; then
			popd -n -0 > /dev/null
		fi
	}
	alias dirs='dirs -v'
	alias dirup="pushd +1"
	alias cdup="pushd +1"
	alias dirdown="pushd -1"
	alias cddown="pushd -1"
}

color(){
	[[ -t 1 || ${_color_force:-0} -eq 1 ]] || return 0
	local mode number
	case ${1:-} in
		*bold*)      mode=1 ;;
		*dim*)       mode=2 ;;
		*underline*) mode=4 ;;
		*blink*)     mode=5 ;;
		*reverse*)   mode=7 ;;
		*hidden*)    mode=8 ;;
		*)           mode=0 ;;
	esac
	case ${1:-} in
		*white*)   number="37" ;;
		*black*)   number="30" ;;
		*red*)     number="31" ;;
		*green*)   number="32" ;;
		*yellow*)  number="33" ;;
		*blue*)    number="34" ;;
		*magenta*) number="35" ;;
		*cyan*)    number="36" ;;
		*)         number="0" ;;
	esac
	printf "\e[${mode};${number}m"
}

colors(){
	local color mode
	for color in white black red green yellow blue magenta cyan; do
		color reset; printf "${color}: "; color bold${color}; printf "bold "; color ${color}; printf "regular\n"
	done
	color
}

_program_load(){
	declare program_name filename="${0/*\/}"
	if [[ "${filename}" =~ ^\.?bashrc$ ]]; then                              ## $0 is (.)?bashrc
		if [[ "${_program_list[@]}" =~ (^| )${1:-__None__}( |$) ]]; then     ##   $1 is a program in list
			program_name="${1}"; shift
		else
			program_name="_bashrc_show_help"                                 ##   $1 is not a program in list
		fi
	elif [[ "${_program_list[@]}" =~ (^| )${filename}( |$) ]]; then          ## $0 is a program in list
		program_name="${filename}"
	else                                                                     ## neither bashrc o program in list, I am a plain non-interactive session
		return 0
	fi
	_source_utilities
	_source_variables
	# At this point, this file is being executed, so we set -euo pipefail, trap, and do exit at the end.
	[[ ${1:-__None__} == "--debug" ]] && shift && set -x
	set -euo pipefail
	trap '_exit $? ${BASH_COMMAND}' ERR SIGINT SIGTERM SIGHUP
	${program_name} "$@"
	exit $?
}

_bashrc_show_help(){
	color blue; printf "make-links"; color; printf " | "; color blue; printf "make-links"; color; echo ": create a link for every available program."
	color blue; printf "disksinfo"; color; echo ": show ata disks information."
	color blue; printf "retention"; color; echo ": helper to mantain a retention with given dates."
	color blue; printf "try"; color; echo ": tries executing a command until it succeeds."
	color blue; printf "float"; color; echo ": execute floating point operations."
	color blue; printf "unit-print"; color; echo ": print units."
	color blue; printf "unit-conversion"; color; echo ": convert between unit."
	color blue; printf "check-ping"; color; echo ": check ping to a host."
	color blue; printf "lvm-show-thinpool-usage"; color; echo ": show thinpool metadata/data usage in percentage."
	color blue; printf "argparse"; color; echo ": argument parser."
	color blue; printf "lowercase"; color; echo ": prints args in lowercase."
	color blue; printf "uppercase"; color; echo ": prints args in uppercase."
	color blue; printf "check-type"; color; echo ": checks input argument to be of a specified type."
	color blue; printf "color"; color; echo ": prints escape codes for a color."
	color blue; printf "extract"; color; echo ": extract archives into subfolders."
	color blue; printf "lock"; color; echo ": lock/unlock given an identifier."
	color blue; printf "pastebin"; color; echo ": upload test file to a public service."
	color blue; printf "testport"; color; echo ": test if a TCP port is open."
	color blue; printf "testcpu"; color; echo ": poor's man cpu bench."
	color blue; printf "repeat"; color; echo ": executes a command continuously."
	color blue; printf "max-mtu"; color; echo ": obtain the maximum mtu to an IP."
	color blue; printf "beep"; color; echo ": beeps."
	color blue; printf "is-number"; color; echo ": returns if an input number is an integer."
	color blue; printf "tmux-send"; color; echo ": sends test to a tmux pane."
	color blue; printf "wait-ping"; color; echo ": Wait until ping to IP succeeds (default interval 1 second)."
	color blue; printf "grepip"; color; echo ": show lines containing IP's from files/stdin."
	color blue; printf "sshconnect"; color; echo ": use ssh with ConnectTimeout=1 and ServerAliveInterval=3"
	color blue; printf "myip"; color; echo ": shows public IP and optionally notices when changes and/or executes a command."
	color blue; printf "status-changed"; color; echo ": given an identifier and the current status exits with return code 1 if status has changed."
	color blue; printf "rescan-scsi-bus"; color; echo ": rescan scsi bus."
	color blue; printf "timer-countdown"; color; echo ": counts down the given time."
	color blue; printf "tmuxac"; color; echo ": attach to or create a named tmux session."
}


_binary[tmuxrc]="H4sICB60gVoCA3RtdXguY29uZgDFWe9u2zgS/+6nmLU2cNKNYjttemiKFLtIt2iBBlc07RaH1FfQMm2zkUhBpOI4uz30Me6A3c/3/V7h3qRPcjMkJUuynThpF+cgSCzO/Ob/cEgF8EzE/BeeaaHk0cGjViuAJ0ewv9c/BBYZccFhJuRIzSBSscozXD9a8UGuVxkfi0tgawneSs0NHCtpMhWHQ0gtQyuXQxQQnvM5HIdDpDtFKrcGRpX0rIXcoUoN6gnhpKA4xgVikaPiiZBajDikTPK4VYFmoJEq9FJvMuNqLcFaQwJYMmWdMYgOa8y58mxrDAqgFHFVM4i4ngrNhjEHneuUlqJYcGmail1RjN9qDlGeZbiOyGYKqIbkMx/srk5jYVpiHOopj2NoG64NfL9tkvwSwl/gNxQ9gjCDju6e/b0XPhp0u5PODhrCof+oDW0nEKLH4P4SdugTKYygE/xK5nzwGnwgDT512qjXUyU7Bs4l0k3xF33GdcRSDrT41fq8bz9e+O99G6yZpV4X16n21bK3KqK3GpKn10lGw4/DFCY5y0YMYsxjFgv8L1UZJYVhMT7jEr5//teTn7uk1t4F8jPJwqUiSCEVKbfPIVTQiZiBJ0/+4biCF2HwqkPyMo4yDMtImseibpCz2FahU7uSvf6BNszkOvQGhMMJAo0IL1GYwBciadSwp0fVNK6uhibWkgKhXqroHD2uqV/hV8n5CJdieoqFQs5AkXUxtBhGKkkYhsGSVl1y6dY1zy44tTc4Ubnmd8o2LL39Hka8Lj4hvBBdKq6855Vsf3N8zWMemT8d32fst5aAMbZi7gyMxbbfX626rSBbgqGEd1PO47fpK3JTKSV8BqGBI2gHv1qOD0zOP4xjNvlkEV2qaAhP8KsYI7k5KqtVyA+k/qcOqlShtF8XEQnN0WPcQdN5aEsh5I+hRt1uqvhUzaRVsoEC7+ucrrq0ybBYeawhEVozM+EaRnmGzQES/NfwJNWNohgJbEFsHhqRcDjo9XrWS5mQE2q6Zip0sfHHDENwIbQw6HrXUSrxcYFBx5Ql9RE+KiG9xhq+s/7/OcbyHImIA3UC31JQLcGvbPPqw7ZU9E9vZyV6Xfkhw4xEPH4J/WV4q+PdwYk9XJJworB/0W6Jv5mXoa93BKap/Rxjf6+F8WV7U8aPdcanGzOe1xnfbswY1xlfb8yoGqkKh3s/2B2dU6L999/Mzhqj27nuhFw3Y+ktzTghMxZsT8sWYKmKz0ukESaa+jkJu1OrPpcZniVghIm53oWxyqKlrYW+OQLsXMQ9wgkPcBPCumG5UQkzIioKSTIstWjK5IRvkIYWBLcNy6XG4/ZanqU9s5RcYyft+JjlsQELszSD+lUvpIv+6mIZTInxNc4iPMO2wCS2MUn9RkjqFd402ttc3+CQsEuR5Il7psaAzRS8hxEJuSVmCbYST37Pb+b3dhfIm8ISnkOuwd5DPY3HuLcHJ3k0xSaJVZtxppWkGXmPAjmzzppMMtLgotijfSR/Iv9rCjuMsQOi9ZQ7GU85BpyGj5tCqP3o6lpszwYgZhnuVNhcjcrmjVzyT8NYJMJAv+d78uoYUWoKyVC4jjLOZbh/8JBOaNnSpIo10c111tVTrMCu4xurru46xnZZDs0EXBLVcRydTUUYO1ZWBGwggjg6t7VhYfymNpQctzSmImlDY6qSWkHtQwdXOwHjfpZB0Fz1R2FdkrQCOncu5macr4cxw2m28XyMZTnF3br5POZjA+1283EmJlN8HpyNJ0cTcs4geG6T1aqf8CSM0jyMFRu5bKywConGXqCpB36pCony5ARPlg8fLPEVIrdnU8USsfNjsD3FIYZ61Q4Ep6E9icBCo93h5Miauju0rINge0k5OICDHat3sG3jWYz8OwDPRIaRjYW0nYO6iV/rYN/OTZrTITk4Y8ZkYphjGgzcpmavPAA7QLlS9G8kfw6Nz3NvAsnAMwW6hYwi0ulmpNiyzBT1sRqOsIVjJyQqgnjWhDj2p3ffKmlcJboXN9DZmYYIX60jtHtmSXbaJDt17bpU7M21OHZzJLJ3N+hVwAVNup8wbphl6KIvn/8ZfPn8Lwoxv8TxLrbTnkupNSnWCbbz1Pbf3yBCx4YjaO+2IRzDfrjTqRYkVVuUidTUCtE2YPu4RRTBd3ZXxD3RVYe91vD7F2Fjz5+y2bkPe5WoOOmbkuCwT8N+59SeO/t0XtBTyJQyP/Z7e5f007kBYL8CsH8XgPsVgPt3AXhQAXhwF4CDCsDBOoACo34ErbmyIAn3qVQZznRlVEwjJG8W1X9N+AC3CYaNAJi9FvPyLeWuHaRICC7jTr2tFf0ZKa4lpqcBleJRA0t3Ts2juGQrdoUdsIJZYpkRqpSIHPbYFeHRY2+h61jRIEKzFiU49ouKK70d2msLY7qvXVzjaSsLayWinkY+qtjOXJvBs+SelYOTSU4HHGTCSWmYqXO0AkEkMO2V0IcNd2IOG+y02vkHJ68vn383NOKYL5//sPCFd0srSTQteAuo49nvYoS2IWR/D6w6mBdY7746vnz+D31byg50N12D+WG9qohtroiLiF6Sh6q6xGnYBC09hAERphIJexA2M7VwO3kqzbgxc7CDK7UcHBhnLPNObaZsJd7ou0JQVXWaXDFxYEaHd9Kvfgtf9alRdKrhdd96ur6Tf209VOWiSHKVFao8jxVWTjM2UjjM2BcBmUutgk5V9arYuFe9ejkNbTYt0re2ZocT9OVF7anr4pJfmsrjY0dsD3iLZhD2aySOs0HzQ7/VskdSdwxylqy+lCyHq5Wr5YhFN5JWGbqix+KsTGsrGUnzYjC631tPA53O0uxfW66Ma2fBWTkf4cNoznBgUvEI57j6Chb1TO6ORDI4DE4rAINNZFl7B2fudcOhBbaPLDBJGFwt6MqBbTBYVm4AZ7fQDFV7IWtFoKkyK47e+Fxcv6bGQsVDsrfOOo3kBy/sd6sQKnPmp/pB8K5Qa+7onvmred/faUisVeo30bG4Sl/oOiycVY/0i+UV0r6Mm1e/qvlrVyEbJm4xT1VmchL8J+beksTBu0Mcb18d4uh6VjXtzQq4a3Hc8WI9xlklBbb+Fm4l4dYIKtRbzw+3TiqpUc/Xr7q8rqXAHCfcDnnVnkP2H/yFysp/uf/wri+lVohymbss8aBXFjJKu/2rn2v0c9M4jnw4jO+v1Ld4h3awWalYG4SZh3RWA6kkb7tUmLk3AVIYlZVUYPepYnUNkrfiRjrcDeacBqSveEvoA+Iun1U24pkPB1WtS7T2N4L30f4/SLHJlNMbmRXmjssrlNZ6nDFtyzm/hmLoKf4HHrkFhdogAAA="
_binary[tmuxrc_version]="59"
_binary[tmuxrc_filepath]="$HOME/.tmux.conf"
_binary[tmuxrc_filemode]="644"
_binary[tmuxrc_rootpath]="/etc/tmux.conf"
_binary[tmuxrc_rootmode]="644"
_binary[tmuxrc_option]="_tmuxrc"

_binary_decode(){
	local file localfile i version
	for file in tmuxrc; do
		[[ ${!_binary[${file}_option]:-0} -eq 1 ]] || continue
		if [[ ${EUID} -eq 0 && ${_binary[${file}_rootpath]:-None} != "None" ]]; then
			local filepath="${_binary[${file}_rootpath]}"
			local filemode="${_binary[${file}_rootmode]}"
		else
			local filepath="${_binary[${file}_filepath]}"
			local filemode="${_binary[${file}_filemode]}"
		fi
		version=0
		if [[ -f "${filepath}" ]]; then
			readarray -t localfile < "${filepath}"
			for (( i=0; i<${#localfile[@]}; i++ )); do
				[[ "${localfile[$i]}" =~ ^" "*#" "*FileVersion=[0-9]+$ ]] && [[ "${localfile[$i]}" =~ [0-9]+ ]] && version="${BASH_REMATCH}" && break
				[[ ${i} -gt 10 ]] && break # FileVersion should be at the start of the file
			done
		fi
		if [[ ${version} -eq 0 || ${version} -lt ${_binary[${file}_version]} ]]; then
			echo "[bashrc] Upgrading ${filepath} from version ${version} to ${_binary[${file}_version]}"
			echo "${_binary[${file}]}" | base64 -d | gunzip > "${filepath}"
			[[ "$(stat -c "%a" "${filepath}")" == ${filemode} ]] || chmod ${filemode} "${filepath}"
		fi
	done
}

_bash_reload(){
	[[ ${FileVersionOld:-} =~ [0-9]+ ]] && unset FileVersionOld && _bash_updated=0
	if [[ ${ps1_bash_update} -lt 20 ]]; then
		ps1_bash_update=$(( ${ps1_bash_update} + 1 ))
		if [[ -f "/tmp/${UID}.$$.bashrcupdate" ]]; then
			_bash_updated=1
			FileVersionOld=${FileVersion}
			rm /tmp/${UID}.$$.bashrcupdate
			. $HOME/.bashrc
		fi
	fi
}

#====================================================================
# Aliases
#====================================================================

_source_aliases_amospalla(){
	alias tnew='tmux new -s'
	alias ls='ls --color -F'
	alias grep='grep --color'
	alias egrep='egrep --color'
	alias fgrep='fgrep --color'
	alias vzlist='vzlist -o ctid,name,ip,status,onboot,laverage,diskspace,physpages,swappages -a'
	alias dstat2='dstat     --time --cpu --disk --io --net --page --sys --mem --swap --int --top-cpu --top-io --top-mem --fs --tcp --proc-count'
	alias dstat2full='dstat --time --cpu --disk --io --net --page --sys --mem --swap --int --top-cpu --top-io --top-mem --fs --tcp --proc-count --full'
}

#====================================================================
# Options
#====================================================================

_source_bash_options(){
	local file="${HOME}/.bashrc.options" file_global="/etc/bashrc.options" file_text
	
	[[ -e "${HOME}/.bashrc_options" && ! -e "${file}" ]] && mv -v "${HOME}/.bashrc_options" "${file}"
	
	[[ ${EUID} -eq 0 && -e "/etc/ps1_bashrc" && ! -e "${file_global}" ]] && \
	mv -v "/etc/ps1_bashrc" "${file_global}"
	
	_bash_options_add(){
		local option="${1}"; local default="${2}"
		if [[ ! "${file_text}" =~ "${option}=" ]]; then
			echo "bashrc: Adding to  ${file}  ${option}=${default}"
			echo "${option}=${default}" >> "${file}"
		fi
	}
	
	[[ -r "${file}" ]] && file_text="$(<"${file}")"
	
	_bash_options_add _ps1_enable 1
	_bash_options_add _ps1_get_performance 0
	_bash_options_add _ps1_performance_file $HOME/.bashrc.performance
	_bash_options_add _ps1_exit_code 1
	_bash_options_add _ps1_tmux 1
	_bash_options_add _ps1_x11_display 1
	_bash_options_add _ps1_time 1
	_bash_options_add _ps1_load 1
	_bash_options_add _ps1_tag 1
	_bash_options_add _ps1_chroot_name 1
	_bash_options_add _ps1_jobs 1
	_bash_options_add _ps1_user_at_host 1
	_bash_options_add _ps1_virtualenv 1
	_bash_options_add _ps1_git 0
	_bash_options_add _ps1_prompt 1
	_bash_options_add _ps1_bash_update 1
	_bash_options_add _tmuxrc 1
	_bash_options_add _histgrep_compact 1
	_bash_options_add _update_enable 0
	_bash_options_add _update_url http://www.amospalla.es/rcver/bash
	
	. "${file}"
	[[ "${_ps1_virtualenv}" == 1 ]] && export VIRTUAL_ENV_DISABLE_PROMPT=1
	[[ -r "${file_global}" ]] && . "${file_global}"
}

#====================================================================
# Utilities
#====================================================================

_source_utilities(){

	_exit(){
		printf "\nError at line: ${2}\n"
		exit ${1}
	}

	argparse(){
		_debug(){
			return
			local i="${substract}"
			while [[ $i -gt 0 ]]; do
				printf "   "
				i=$(( $i -1 ))
			done
			echo $@
		}
		_argparse_process_args(){
			_check_type(){
				local value=$(lowercase "${2}")
				case "${1}" in
					integer) [[ "${value}" =~ ^[0-9]+$ ]] ;;
					number) [[ "${value}" =~ ^-?([0-9]+('.'[0-9]+)?|'.'[0-9]+)$ ]] ;;
					bool|boolean) [[ "${value}" =~ ^true|false|1|0|on|off$ ]] ;;
					diu)
						[[ "${value}" =~ ^([0-9]+('.'[0-9]+)?|'.'[0-9]+)([[:space:]]*(b|bytes?|[kmgtpezyxsd](b|ib)?|(kilo|mega|giga|tera|peta|exa|zetta|yotta|kibi|mebi|gibi|tebi|pebi|exbi|zebi|yobi)bytes?))?$ ]]
						;;
					time)
						[[ "${value}" =~ ^([[:space:]]*([0-9]+('.'[0-9]+)?|'.'[0-9]+)([[:space:]]*(s(ec(onds?)?)?|m(in(utes?)?)?|h(ours?)?|d(ays?)?|w(eeks?)?|months?|y(ears?)?)))*$ ]]
						;;
					ip) echo "${value}" | grep -qE "^${_ip_regex}$"
				esac
			}
			process_token(){
				local input_token="${1}"
				_debug "process_token: input_token (${input_token}) tokens (${tokens[@]}) token (${token}) type_input (${type_input})"
				if [[ ${type_input} -eq 1 ]]; then # {arg}
					local vartype="${token/*:}"
					if ! _check_type "${vartype}" "${input_token}"; then
						if [[ ${substract} -eq 0 ]]; then ## if this is the root of _argparse_process_args then optional=0, else it is optional
							echo "Error: value '${input_token}' is not of type '${vartype}'."
							exit 1
						else
							return 1
						fi
					fi
					arguments["${token/:*}"]="${input_token}"
					type_input=0; return 0
				else
					local -i i j
					if [[ ${tokens[0]:0:1} == "-" ]]; then            ## -x|--xxx format
						for (( i=0; i<${#tokens[@]}; i++ )); do
							if [[ "${input_token}" == "${tokens[$i]}" ]]; then
								for (( j=0; j<${#tokens[@]}; j++ )); do arguments["${tokens[$j]}"]=1; done;
								return 0
							fi
						done
					else
						for (( i=0; i<${#tokens[@]}; i++ )); do
							if [[ "${input_token}" == "${tokens[$i]}" ]]; then
								arguments["${input_token}"]=1;
								return 0
							fi
						done
					fi
				fi
				return 1 # Token and input had no coincidence
			}
			
			substract_add(){ substracts[${substract}]=$(( ${substracts[${substract}]} + ${1} )); }
			substract_print(){ echo "substract_print: ${substracts[${substract}]}"; }
			token_add_char(){ token="${token:-}${template_args:${position}:1}"; }
			pos_inc(){ position+=1; }
			optional_not_ended(){ [[ ${optional} -eq 1 && ${optional_stack} -ne 0 ]]; }
			optional_ended(){ [[ ${optional} -eq 1 && ${optional_stack} -eq 0 ]]; }
			remaining_chars(){ [[ ${position} -le ${len} ]]; }
			
			local -i substract=${1} ec; shift
			local token="" next_input_token template_args="${1} "; shift
			local -i len=${#template_args} position=0 type_input=0 optional=0 optional_stack=0 substract_next=$(( ${#substracts[@]} + 1 ))
			local -a tokens=()
			substracts[${substract}]=0
			
			_debug ""
			_debug "${substract}: _argparse_process_args substract(${substract}) template_args(${template_args}) args($@)"
			
			while remaining_chars; do
				case ${template_args:${position}:1} in
					" ")	_debug "_argparse_process_args: next char is ' ' ${position}"
							if optional_not_ended; then           # still reading an optional token [..]
								token_add_char; pos_inc; continue
							elif optional_ended; then             # Ended reading an optional token, call myself recursively
								_debug "  _argparse_process_args: optional ended"
								if _argparse_process_args ${substract_next} "${token}" "$@"; then
									substract_add "${substracts[${substract_next}]}"
									shift "${substracts[${substract_next}]}"
									_debug "Recursive call returned shift (${substracts[${substract_next}]})"
								else
									_debug "Recursive call returned error"
								fi
								optional=0
							else     # Process next token normally
								tokens[${#tokens[@]}]="${token}"
								[[ "${token}" =~ '...'$ ]] && pos_inc && continue # {files...} like, must end with three dots and are expected to be the last argument.
								next_input_token="${1:-}"; shift
								[[ "${#next_input_token}" -eq 0 ]] && return 1
								if [[ ${type_input} -eq 0 ]]; then
									[[ ( "${next_input_token:0:1}" == "-" || ${token:0:1} == "-" ) && "${next_input_token:0:1}" != "${token:0:1}" ]] && return 1
								fi
								if process_token "${next_input_token}"; then
									_debug "  _argparse_process_args: token processed, substract 1"
									substract_add 1
								else
									_debug "  _argparse_process_args: token processed with error, return 1"
									return 1
								fi
							fi
							token=""; tokens=(); pos_inc ;;
					"|")	if [[ ${optional} -eq 0 ]]; then
								tokens[${#tokens[@]}]="${token}"; token=""; pos_inc
							else
								token_add_char; pos_inc
							fi ;;
					"{")	[[ ${optional} -eq 0 ]] && type_input=1 || token_add_char; pos_inc ;;
					"}")	[[ ${optional} -eq 0 ]] || token_add_char; pos_inc ;;
					"[")	[[ ${optional} -eq 0 ]] && optional=1 || token_add_char; optional_stack+=1 && pos_inc ;;
					"]")	optional_stack=$(( ${optional_stack} -1 ))
							[[ ${optional_stack} -gt 0 ]] && token_add_char; pos_inc ;;
					  *)	token_add_char; pos_inc ;;
				esac
			done
			if [[ ${substract} -eq 0 ]]; then # when substract=0 we are in the root of the recursive process
				# {files...} like, must end with three dots, we expect there are pending input arguments to process
				if [[ "${token}" =~ '...'$ ]]; then # last argument_parameter was {foo...} like
					[[ $# -gt 0 ]] && ec=0 || ec=1
				elif [[ "${template_args}" =~ "["[0-9a-zA-Z_-.:@#%]+"...] "$ ]]; then   # last argument_parameter was [foo...] like
					local arg_last="${BASH_REMATCH}" && arg_last=${arg_last/[} && arg_last=${arg_last/...] }
					arguments[${arg_last}]=1
					[[ $# -gt 0 ]] && ec=0 || ec=0
				else
					[[ $# -gt 0 ]] && ec=1 || ec=0
				fi
			fi
			_debug "${substract}: _argparse_process_args end (${substract}) remaining ($@)"
			[[ ${substract} -eq 0 ]] && remaining_args_num=$#
			return ${ec:-0}
		}
		[[ $- =~ x ]] && set +x && local debug=1 || local debug=0
		local i args remaining_args_num
		local -a substracts=() # Number of input arguments to shift array
		[[ ("${1:-}" =~ ^-h|--help$ && ${#arguments_list[@]} -eq 0 ) || ($# -eq 0 && ${#arguments_list[@]} -eq 0) ]] && echo "execute argparse-create-template" && exit 0
		for (( i=0; i<${#arguments_list[@]}; i++ )); do
			args="${arguments_list[$i]}"; arguments_shift=0
			[[ $# -eq 0 && "${!args}" == "" ]] && return 0       # arguments and argument_template are both empty
			if _argparse_process_args 0 "${!args}" "$@"; then
				arguments_shift="$(( $# - ${remaining_args_num} ))"
				[[ ${debug} -eq 1 ]] && set -x
				return 0
			fi
		done
		[[ ${debug} -eq 1 ]] && set -x
		argparse_show_help 1
	}

	argparse_show_help(){
		_argparse_show_help_argument(){
			local template_args="${1} "; shift
			local -i len=${#template_args} position=0 old_position=0 optional=0 optional_stack=0 bracket=0
			print_color(){
				[[ ${optional} -eq 1 ]] && color green || color red
				[[ ${optional_stack} -eq 0 ]] && optional=0 || true
			}
			
			while [[ ${position} -le ${len} ]]; do
				case ${template_args:${position}:1} in
					"{") bracket=1 ;;
					"}") bracket=0 ;;
					"[") optional=1; optional_stack+=1 ;;
					"]") optional_stack=$(( ${optional_stack} -1 )) ;;
					" ") print_color
						 echo -n "${template_args:${old_position}:$(( ${position} - ${old_position} ))}"
						 old_position="${position}" ;;
				esac
				position+=1
			done
			color
		}
		local i args len=11 len2 hcolor=boldwhite
		local -a key value _arguments_parameters=('[-h|--help]: show this help.')
		
		# Usage
		color ${hcolor}; printf "Usage:\n"
		for (( i=0; i<${#arguments_list[@]}; i++ )); do
			args="${arguments_list[$i]}"
			color boldblue; printf "  ${arguments_description[0]} "
			color blue; _argparse_show_help_argument "${!args}"
			printf "\n"
		done
		
		# Parameters
		color ${hcolor}; printf "\nParameters:\n"
		for (( i=0; i<${#arguments_parameters[@]}; i++ )); do
			len2="${arguments_parameters[$i]/: *}"
			[[ ${len} -lt ${#len2} ]] && len=${#len2}
		done
		len=$(( ${len} + 2 ))
		for (( i=0; i<${#_arguments_parameters[@]}; i++ )); do
			key[${i}]="${_arguments_parameters[$i]/: *}"
			value[${i}]="${_arguments_parameters[$i]/*: }"
			color blue; printf -- "%${len}s" "${key[${i}]}";
			color; printf -- ": ${value[${i}]}\n";
		done
		for (( i=0; i<${#arguments_parameters[@]}; i++ )); do
			key[${i}]="${arguments_parameters[$i]/: *}"
			value[${i}]="${arguments_parameters[$i]/*: }"
			color blue; printf -- "%${len}s" "${key[${i}]}";
			color; printf -- ": ${value[${i}]}\n";
		done
		
		# Examples
		if [[ ${#arguments_examples[@]} -gt 0 ]]; then
			color ${hcolor}
			[[ ${#arguments_examples[@]} -gt 2 ]] && printf "\nExamples:\n" || printf "\nExample:\n"
			for (( i=0; i<${#arguments_examples[@]}; i+=2 )); do
				color blue; printf -- "  ${arguments_examples[$i]}"
				color; [[ "${#arguments_examples[$(( $i + 1 ))]}" -gt 0 ]] && printf -- ": ${arguments_examples[$(( $i + 1 ))]}\n" || printf '\n'
			done
		fi
		
		# Description
		if [[ "${#arguments_description[@]}" -gt 1 ]]; then
			color ${hcolor}; printf "\nDescription:\n"
			color
			for (( i=0; i<${#arguments_description[@]}; i++ )); do
				[[ ${i} -eq 0 ]] && continue
				printf -- "${arguments_description[${i}]}\n"
			done
		fi
		
		# Additional information
		if [[ ${#arguments_extra_help[@]} -gt 0 ]]; then
			color ${hcolor}; printf "\nAdditional information:\n"; color
			for (( i=0; i<${#arguments_extra_help[@]}; i++ )); do
				printf -- "${arguments_extra_help[$i]}\n"
			done
		fi
		
		color
		exit "${1:-0}"
	}

	argparse-create-template(){
		arguments_list=(args1)
		args1='[-o|--overwrite] {file}'
		arguments_description=('argparse-create-template' 'Creates a bash skeleton to use argparse')
		arguments_parameters=( '[-o|--overwrite]: overwrite file.' '{file}: path to create file' )
		arguments_extra_help=( 'Argparse will exit correctly if input arguments match some of the templates in arguments_list[].'
		                       'When using a parameter like foo... its content will remain in $@ (everything else is shifted).'
		                       'Arguments_list[] can not be empty (but they references can).'
		                       'Parameters like foo... (3 dots) can only be used as the last parameter, and always between brackets or curly brackets.'
		                       'To see available argument types see the program check-type.')
		argparse "$@" && shift ${arguments_shift}
		[[ -f "${arguments[file]}" && ${arguments[-o]:-0} -eq 0 ]] && echo "File ${arguments[file]} already exists, use --overwrite to overwrite." && exit 1
		echo "#!/bin/bash" > "${arguments[file]}"
		echo "" >> "${arguments[file]}"
		echo "source $(readlink -f "${0}"); _source_utilities" >> "${arguments[file]}"
		echo "args1='[-n|--number [{number:integer}]] param1 [-c|--count] [mode1|mode2] [files...]' # for types, see check-type program" >> "${arguments[file]}"
		echo "args2='run'" >> "${arguments[file]}"
		echo "args3='list'" >> "${arguments[file]}"
		echo "arguments_list=(args1 args2 args3)" >> "${arguments[file]}"
		echo "arguments_description=('"$(basename "${arguments[file]}")"'" >> "${arguments[file]}"
		echo "                       'Some description.')" >> "${arguments[file]}"
		echo "arguments_parameters=( '[-n|--number [{number}]]: set number with an optional value (integer).'" >> "${arguments[file]}"
		echo "                       'param1: set param1.'" >> "${arguments[file]}"
		echo "                       '[-c|--count]: set count.'" >> "${arguments[file]}"
		echo "                       'mode1|mode2: set mode1 or mode2 (mutually exclusive).'" >> "${arguments[file]}"
		echo "                       '[files...]: optionally specify files.')" >> "${arguments[file]}"
		echo "arguments_examples=('$ "$(basename "${arguments[file]}")" param1 mode1' 'some description'" >> "${arguments[file]}"
		echo "                    '$ $(basename "${arguments[file]}") run' 'description for this one')" >> "${arguments[file]}"
		echo "arguments_extra_help=('Some extra help to show.')" >> "${arguments[file]}"
		echo "" >> "${arguments[file]}"
		echo 'argparse "$@" && shift ${arguments_shift}' >> "${arguments[file]}"
		echo "" >> "${arguments[file]}"
		echo "for param in '-n' '--number' 'param1' '-c' '--count' 'mode1' 'mode2' run list; do" >> "${arguments[file]}"
		echo '    printf "%8s: " "${param}"; echo "${arguments["${param}"]:-}"' >> "${arguments[file]}"
		echo 'done | column -t' >> "${arguments[file]}"
		echo '' >> "${arguments[file]}"
		echo 'echo ""' >> "${arguments[file]}"
		echo 'echo remaining args:' >> "${arguments[file]}"
		echo 'for arg in "$@"; do echo "${arg}"; done' >> "${arguments[file]}"
		[[ -x "${arguments[file]}" ]] || chmod u+x "${arguments[file]}"
		printf "File ${arguments[file]} created, try to run it with:\n${arguments[file]} -h\n${arguments[file]} -n 1 param1 -c mode2 a b c\n"
	}

	unit-print(){
		arguments_list=(args1)
		args1='{unit-type} {unit}'
		arguments_description=('unit-print' 'Print unit.')
		arguments_parameters=( '{unit-type}: diu | time.'
		                       '{unit}: unit to display (ie byte/kb/kib/minutes/day ...)' )
		arguments_examples=( '$ unit-print diu mb' 'print a mebagyte in bytes.'
		                        '$ unit-print time hour' 'print an hour in seconds.' )
		argparse "$@" && shift ${arguments_shift}
		arguments[unit]="$(lowercase "${arguments[unit]}")"
		if [[ ${arguments[unit-type]} == diu ]]; then
			case ${arguments[unit]} in
				b)           echo 1 ;;
				k|kib*)      echo 1024 ;;
				k*)          echo 1000 ;;
				m|mib|me*)   echo 1048576 ;;
				m*)          echo 1000000 ;;
				g|gib*)      echo 1073741824 ;;
				g*)          echo 1000000000 ;;
				t|tib|tebi*) echo 1099511627776 ;;
				t*)          echo 1000000000000 ;;
				p|pib|peb*)  echo 1125899906842624 ;;
				p*)          echo 1000000000000000 ;;
				e|eib|exb*)  echo 1152921504606850000 ;;
				e*)          echo 1000000000000000000 ;;
				z|zib|zeb*)  echo 1180591620717410000000 ;;
				z*)          echo 1000000000000000000000 ;;
				y|yib|yob*)  echo 1208925819614630000000000 ;;
				y*)          echo 1000000000000000000000000 ;;
			esac
		elif [[ ${arguments[unit-type]} == time ]]; then
			case ${arguments[unit]} in
				s*) echo 1 ;;
				m*) echo 60 ;;
				h*) echo 3600 ;;
				d*) echo 86400 ;;
				w*) echo 604800 ;;
				mo*) echo 2628000 ;;
				y*) echo 31536000 ;;
			esac
		fi
	}

	lvm-show-thinpool-usage(){
		arguments_list=(args1)
		args1='data|metadata {vg} {lv}'
		arguments_description=('lvm-show-thinpool-usage' 'Show lvm thinpool data/metadata percentage usage.')
		arguments_parameters=('data|metadata: type to check.'
		                      '{vg} {lv}: LVM group and volume.' )
		argparse "$@" && shift ${arguments_shift}
		if [[ ! -e /dev/mapper/${arguments[vg]//-/--}-${arguments[lv]//-/--} ]]; then
			echo "Error: ${arguments[vg]}/${arguments[lv]} does not exist"
			exit 1
		fi
		local value
		if [[ ${arguments[data]:-0} -eq 1 ]]; then
			value=$(/sbin/lvs --noheadings -odata_percent ${arguments[vg]}/${arguments[lv]})
		elif [[ ${arguments[metadata]:-0} -eq 1 ]]; then
			value=$(/sbin/lvs --noheadings -ometadata_percent ${arguments[vg]}/${arguments[lv]})
		fi
		trim "${value}"
	}

	check-lvm-usage(){
		arguments_list=(args1)
		args1='[-m|--message] [-i|--invert] [-q|--quiet] data|metadata {value:integer} {vg} {lv}'
		arguments_description=('check-lvm-usage' 'Check data or metadata for a LVM thinpool is below a given value.')
		arguments_parameters=( '[-m|--message]: show a message if test fails.'
		                        '[-i|--invert]: fail when get reply.'
								'data|metadata: type to check.'
								'{value}: threshold.'
								'{vg} {lv}: LVM group and volume.' )
		argparse "$@" && shift ${arguments_shift}
		if [[ ! -e /dev/mapper/${arguments[vg]//-/--}-${arguments[lv]//-/--} ]]; then
			echo "Error: ${arguments[vg]}/${arguments[lv]} does not exist"
			exit 1
		fi
		if [[ ${arguments[data]:-0} -eq 1 ]]; then
			local current=$(/sbin/lvs --noheadings -odata_percent ${arguments[vg]}/${arguments[lv]})
			local type=data
		elif [[ ${arguments[metadata]:-0} -eq 1 ]]; then
			local current=$(/sbin/lvs --noheadings -ometadata_percent ${arguments[vg]}/${arguments[lv]})
			local type=metadata
		fi
		if [[ ${current/.*} -gt ${arguments[value]} ]]; then
			[[ ${arguments[-q]:-0} -eq 0 ]] && trim "${current}"
			exit 1
		fi
	}

	check-ping(){
		arguments_list=(args1)
		args1='[-m|--message] [-i|--invert] {host}'
		arguments_description=('check-ping' 'Check if host replies to ping.')
		arguments_parameters=( '[-m|--message]: show a message if test fails.'
		                        '[-i|--invert]: fail when get reply.'
								'{host}: host to check.' )
		argparse "$@" && shift ${arguments_shift}
		ping -w1 -c1 ${arguments[host]} >/dev/null 2>&1 && local pinged=1 || local pinged=0
		if [[ ${pinged} -eq 1 && ${arguments[-i]:-0} -eq 1 ]]; then
			[[ ${arguments[-m]:-0} -eq 1 ]] && echo "Error: could ping to '${arguments[host]}'."; exit 1
		elif [[ ${pinged} -eq 0 && ${arguments[-i]:-0} -eq 0 ]]; then
			[[ ${arguments[-m]:-0} -eq 1 ]] && echo "Could not ping to '${arguments[host]}' with a 1 second timeout."; exit 1
		fi
	}

	unit-conversion(){
		arguments_list=(args1 args2)
		args1='diu [-d|--decimals {decimals}] {unit} {units...}'
		args2='time [-d|--decimals {decimals}] {unit} {units...}'
		arguments_description=('unit-conversion' 'Convert between units.')
		arguments_parameters=( 'time: do time conversion to the specified unit.'
		                        'diu: do digital information unit conversion to the specified unit.'
								'[-d|--decimals {decimals}]: print up to specified decimals (by default 2 if --decimals is used).' )
		arguments_examples=( '$ unit-conversion time -d 2 weeks "24m" "3h"' 'convert to months using with two decimals.'
		                        '$ unit-conversion diu megabytes 0.25G' 'convert 0.25G to megabytes.' )
		argparse "$@" && shift ${arguments_shift}
		local i src=0 dst=0 from_value from_base from_type to_base integer decimal decimals=2 this
		
		if [[ ${arguments[diu]:-0} -eq 1 ]]; then
			[[ ${1} =~ [0-9.]+ ]] && from_value=${BASH_REMATCH}
			if ! check-type diu "${1}"; then
				echo "Error: ${1} is not a diu type."
				exit 1
			fi
			from_type=${1/$from_value}
			from_base=$(unit-print diu ${from_type})
			to_base=$(unit-print diu ${arguments[unit]})
			src=$(float "${from_value}" '*' "${from_base}")
			dst=$(float "${src}" "/" "${to_base}")
		elif [[ ${arguments[time]:-0} -eq 1 ]]; then
			for (( i=1; i<=$#; i++ )); do
				this=${!i}
				if ! check-type time "${this}"; then
					echo "Error: ${this} is not a time type."
					exit 1
				fi
				[[ ${this} =~ [0-9.]+ ]] && from_value=${BASH_REMATCH}
				from_type=${this/$from_value}
				from_base=$(unit-print time ${from_type})
				to_base=$(unit-print time ${arguments[unit]})
				src=$( float ${src} + $( float ${from_value} '*' ${from_base}) )
				dst=$( float ${src} '/' ${to_base})
			done
		fi
		integer=${dst/\.*}
		decimal=${dst/*\.}
		[[ ${arguments[-d]:-0} -eq 1 ]] && decimals=${arguments[decimals]}
		printf "${integer}"
		[[ ${decimals} -gt 0 ]] && printf "." && echo "${decimal:0:${decimals}}" || echo ""
	}

	float(){
		arguments_list=(args1); args1='[-d|--decimals {decimals:number}] {number1:number} {operator} {number2:number}'
		arguments_description=('float' 'Execute a floating point operation')
		arguments_parameters=( '[-d|--decimals {decimals}]: specify number to decimals to display (by default all)'
		                       '{number1}: first opperand.'
							   '{operator}: operation to do.'
							   '{number2}: second opperand.')
		argparse "$@" && shift ${arguments_shift}
		local result integer decimal
		case ${arguments[operator]} in
			"/") result=$(echo ${arguments[number1]} ${arguments[number2]} | awk '{printf "%.20f\n",$1/$2}') ;;
			"*") result=$(echo ${arguments[number1]} ${arguments[number2]} | awk '{printf "%.20f\n",$1*$2}') ;;
			"+") result=$(echo ${arguments[number1]} ${arguments[number2]} | awk '{printf "%.20f\n",$1+$2}') ;;
			"-") result=$(echo ${arguments[number1]} ${arguments[number2]} | awk '{printf "%.20f\n",$1-$2}') ;;
		esac
		integer=${result/.*}; decimal=${result/*.}
		if [[ ${arguments[-d]:-0} -eq 1 ]]; then
			printf -- "${integer}"
			[[ ${arguments[decimals]} -gt 0 ]] && echo ".${decimal:0:${arguments[decimals]}}" || echo ""
		else
			echo "${integer}.${decimal}"
		fi
	}

	check-type(){
		arguments_list=(args1); args1='{type} {string}'
		arguments_description=('check-type' 'Checks if the supplied string is of a certain type.')
		arguments_parameters=( '{type}: bool[ean] | integer | number | time'
							   '{string}: string to check.')
		arguments_extra_help=( 'Types:'
		                       '  bool: true|false|0|1|on|off'
							   '  integer: n'
							   '  number: (-)?{n | n.n | .n}'
							   '  diu: {number}[b|bytes|k|kb|kib|kilobytes... (digital information unit).'
							   '  time: ( {number}[[s[ec[ond[s]]]|m|h|d|w|month|] )*.'
							   '  ip: x.x.x.x(/yy)?.')
		argparse "$@" && shift ${arguments_shift}
		local value="$(lowercase "${arguments[string]}")"
		case "${arguments[type]}" in
			integer) [[ "${value}" =~ ^[0-9]+$ ]] ;;
			number) [[ ${value} =~ ^-?([0-9]+('.'[0-9]+)?|'.'[0-9]+)$ ]] ;;
			bool|boolean) [[ "${value}" =~ ^true|false|1|0|on|off$ ]] ;;
			diu)
				[[ "${value}" =~ ^([0-9]+('.'[0-9]+)?|'.'[0-9]+)([[:space:]]*(b|bytes?|[kmgtpezyxsd](b|ib)?|(kilo|mega|giga|tera|peta|exa|zetta|yotta|kibi|mebi|gibi|tebi|pebi|exbi|zebi|yobi)bytes?))?$ ]]
				;;
			time)
				[[ "${value}" =~ ^([[:space:]]*([0-9]+('.'[0-9]+)?|'.'[0-9]+)([[:space:]]*(s(ec(ond)?s?)?|m(in(ute?)?s?)?|h(ours?)?|d(ays?)?|w(eeks?)?|months?|y(ears?)?)))*$ ]]
				;;
			ip) echo "${value}" | grep -qE "^${_ip_regex}$"
		esac
	}

	disksinfo(){
		_diskinfo_getdevice(){
			local i dev
			for (( i=0;i<${#devices[@]}; i++ )); do
				dev="$(echo "${devices[$i]}" | awk '{print $1}' | sed 's/\./\\\./')"
				[[ "$(readlink -f /sys/block/${1})" =~ ${dev}/(ata|virtio|usb) ]] && dev="${devices[$i]}" && break
			done
			printf ${dev// /_}
		}
		
		_diskinfo_read(){
			local name i
			for name in $(find /sys/block -type l); do
				name=${name/*\/}; [[ ${name} =~ sd[a-z]$ ]] && i=${#names[@]} || continue
				names[$i]="${name}"
				[[ $(readlink -f /sys/block/${names[$i]}) =~ (ata|virtio|usb)[0-9]+ ]] && ports[$i]=${BASH_REMATCH} || ports[$i]="."
				discards[$i]="$(lsblk -Ddn /dev/${names[$i]} | awk '{print $4}' || true)"
				[[ ${discards[$i]:0:1} -eq 0 ]] && discards[$i]=0 || discards[$i]=1
				sizes[$i]=$(( $(</sys/class/block/${names[$i]}/size) * 512 ))
				sizes2[$i]="$((  ${sizes[$i]} / 1024 / 1024 / 1024 ))"
				sizes10[$i]="$(( ${sizes[$i]} / 1000 / 1000 / 1000 ))"
				vendors[$i]="$(</sys/class/block/${names[$i]}/device/vendor)"
				[[ ${vendors[$i]} =~ ^ATA[[:space:]]+$ ]] && vendors[$i]="."
				vendors[$i]=$( echo "${vendors[$i]}" | sed -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+/_/g' )
				models[$i]="$(</sys/class/block/${names[$i]}/device/model)"
				models[$i]=$( echo "${models[$i]}" | sed -e 's/[[:space:]]*$//' -e 's/[[:space:]]\+/_/g' )
				adapters[$i]="$(_diskinfo_getdevice "${names[$i]}")"
				if [[ -e /sys/class/block/${names[$i]}/device/wwid ]]; then
					serials[$i]="$(</sys/class/block/${names[$i]}/device/wwid)" || true
					serials[$i]="${serials[$i]:52:999}"
					[[ ${#serials[$i]} -eq 0 ]] && serials[$i]="."
				else
					serials[$i]="."
				fi
			done
		}
		
		_diskinfo_print(){
			local -i i
			echo "name port discard size size vendor model serial adapter"
			for (( i=0; i<${#names[@]}; i++ )); do
				printf "${names[$i]} ${ports[$i]} ${discards[$i]} ${sizes10[$i]} ${sizes2[$i]} ${vendors[$i]} ${models[$i]} ${serials[$i]} ${adapters[$i]}\n"
			done
		}
		
		args1=''; arguments_list=(args1)
		arguments_description=( 'disksinfo' 'Show disks information. Needs root privileges to run.')
		argparse "$@" && shift ${arguments_shift}
		[[ ${EUID} -ne 0 ]] && echo "Need root privileges." && exit 1
		
		local -a devices=() names=() ports=() discards=() sizes=() sizes2=() sizes64=() vendors=() models=() adapters=() serials=()
		readarray -t devices < <(lspci)
		_diskinfo_read
		_diskinfo_print | sort -k 1,1 | column -t
	}

	extract(){
		args1='[-d|--delete] {path}'; arguments_list=(args1)
		arguments_description=( 'extract' 'Extract all archives into subfolders. Supported extensions: zip, rar.')
		arguments_parameters=( '[-d|--delete]: delete source archives files after extraction.'
							   '{path}: path where to look for files (default current path)')
		argparse "$@" && shift ${arguments_shift}
		
		folder-writable --message "${arguments[path]:-.}" || exit 1
		
		local i extension file folder status=() ec
		local extensions=(zip unzip rar unrar)
		for (( i=0; i<${#extensions[@]}; i=i+2 )); do
			program-exists ${extensions[$(($i+1))]} || continue
			for file in "${arguments[path]:-.}/"*.${extensions[$i]}; do
				[[ "${file}" == "${arguments[path]:-.}/*.${extensions[$i]}" ]] && continue
				folder="${file:0:-4}"
				if ! mkdir "${folder}" >/dev/null 2>&1; then
					status[${#status[@]}]="0${file}: could not create folder '${folder}'."
					continue
				fi
				if [[ ${extensions[$i]} == "zip" ]]; then
					unzip "${file}" -d "${folder}" && ec=0 || ec=1
				elif [[ ${extensions[$i]} == "rar" ]]; then
					unrar x "${file}" "${folder}" && ec=0 || ec=1
				fi
				if [[ ${ec} -eq 0 ]]; then
					status[${#status[@]}]="1${file}: extracted."
					[[ ${arguments[-d]:-0} -eq 1 ]] && rm "${file}"
				else
					status[${#status[@]}]="0${file}: error."
				fi
			done
		done
		
		if [[ ${#status[@]} -gt 0 ]]; then
			color blue; printf "\nDone:\n"
			for (( i=0; i<${#status[@]}; i++ )); do
				[[ "${status[$i]:0:1}" -eq 0 ]] && color red || color green
				echo "${status[$i]:1}"
			done
			color
		else
			echo "No files to extract."
		fi
	}

	lock(){
		arguments_list=(args1 args2 args3 args4 args5)
		args1='[-p|--path {path}] [-q|--quiet] lock {id} [command...]'
		args2='[-p|--path {path}] unlock {id}'
		args3='[-p|--path {path}] get {id}'
		args4='[-p|--path {path}] set {id} {max}'
		args5='[-p|--path {path}] list'
		arguments_description=( 'lock' 'Locks the named identifier so other one trying to acquire a lock waits for it to be unlocked.')
		arguments_parameters=( '[-p|--path {path}]: path where to store locks (by default /tmp/bashrclock.{uid}.)'
		                       '[-q|--quiet]: quiet mode.'
		                       'lock {id} [command]: lock the specified id and optionally execute a command and unlock at once.'
		                       'unlock {id}: unlock the specified id.'
		                       'set {id} {max}: set the maximum number of concurrent accesses.'
		                       'get {id}: get the maximum number of concurrent accesses.'
							   'list: list ids.')
		arguments_examples=( '$ lock lock id1 && echo "foo"; lock unlock id1' 'sets an unnamed lock, execute a program and unlock.'
		                     '$ lock lock id1 echo foo' 'execute echo foo inside a lock and unlock.')
		argparse "$@" && shift ${arguments_shift}
			
		_lock_error(){
			trap - SIGINT SIGTERM SIGHUP
			[[ ${sub_lock} -eq 1 ]] && rmdir "${basefolder}/${id}.sublock"
			_lock_remove_waiting
			_lock_remove_running
			exit 1
		};
		trap _lock_error ERR SIGINT SIGTERM SIGHUP
		
		_lock_sub_lock(){
			while ! mkdir "${basefolder}/${id}.sublock" 2>/dev/null; do
				sleep 0.1 || exit 1
			done
			sub_lock=1
			_lock_remove_stalled
		}
				
		_lock_sub_unlock(){
			rmdir "${basefolder}/${id}.sublock" && sub_lock=0 || return
		}
		
		_lock_list(){
			local file first=1 line tmp
			find "${basefolder}" -maxdepth 1 -type f -name "*.waiting" | sed -e "s;${basefolder}/;;" -e "s/\.waiting//" | while read file; do
				[[ ${first} -eq 1 ]] && first=0 || printf "\n"
				printf "${file} "
				if [[ -f "${basefolder}/${file}.max" ]]; then
					printf "(max $(cat "${basefolder}/${file}.max")):\n"
				else
					printf "(max 1):\n"
				fi
				for tmp in running waiting; do
					if [[ -f "${basefolder}/${file}.${tmp}" ]]; then
						printf "${tmp}:"
						if [[ $(cat "${basefolder}/${file}.${tmp}" | wc -l) -eq 0 ]]; then
							printf " none\n"
						else
							printf "\n"; cat "${basefolder}/${file}.${tmp}" | while read line; do
								printf "  ${line}\n"
							done
						fi
					else
						printf "${tmp}: none\n"
					fi
				done
			done
		}
		
		_lock_get_max(){
			[[ -f "${basefolder}/${id}.max" ]] && cat "${basefolder}/${id}.max" || echo 1
		}
		
		_lock_set_max(){
			echo "${arguments[max]}" > "${basefolder}/${id}.max"
		}
		
		_lock_get_used_slots(){
			local file
			if [[ -f "${basefolder}/${id}.running" ]]; then
				readarray -t file < "${basefolder}/${id}.running"
				echo "${#file[@]}"
			else
				echo 0
			fi
		}
		
		_lock_wait(){
			local max_slots used_slots am_i_next
			local chars="-\|/"
			local -i current_char=0 i
			while [[ ${found_free_slot} -eq 0 ]]; do
				_lock_sub_lock
				max_slots=$(_lock_get_max ${id})
				used_slots=$(_lock_get_used_slots)
				if [[ ${used_slots} -lt ${max_slots} ]] && _lock_am_i_next; then
					_lock_add_running "$@"
					_lock_remove_waiting
					found_free_slot=1
				fi
				_lock_sub_unlock
				if [[ ${found_free_slot} -eq 0 && ${arguments[quiet]:-0} -eq 1 ]]; then
					read -t4 >/dev/null || true
				elif [[ ${found_free_slot} -eq 0 && ${arguments[quiet]:-0} -eq 0 ]]; then
					for i in {1..16}; do
						current_char+=1 && printf "\r${chars:$(( ${current_char} % 4 )):1}"
						read -t0.25 2>/dev/null || true
					done
				fi
			done
			
			[[ ${arguments[quiet]:-0} -eq 0 ]] && printf "\r \r" || true
			if [[ $# -gt 0 ]]; then
				"$@" && ec=0 || ec=1
				_lock_sub_lock; _lock_remove_running; _lock_sub_unlock
			else
				sed -i "s/^${EUID} $$/unnamed/" "${basefolder}/${id}.running"
			fi
		}
		
		_lock_remove_running(){
			sed -i "/^${EUID} $$/d" "${basefolder}/${id}.running"
		}
		
		_lock_remove_running_unnamed(){
			if [[ ! -f "${basefolder}/${id}.running" ]]; then
				echo "No lock acquired."
				return 1
			fi
			
			local -i i found=0
			local -a text
			readarray -t text < "${basefolder}/${id}.running"
			rm "${basefolder}/${id}.running"
			for (( i=0; i<${#text[@]}; i++ )); do
				[[ "${text[$i]}" == 'unnamed' ]] && [[ ${found} -eq 0 ]] && found=1 && continue
				echo "${text[$i]}" >> "${basefolder}/${id}.running"
			done
			if [[ ${found} -eq 0 ]]; then
				echo "No lock acquired."
				return 1
			fi
		}
		
		_lock_add_running(){
			if [[ $# -eq 0 ]]; then
				echo "${EUID} $$" >> "${basefolder}/${id}.running"
			else
				echo "${EUID} $$ $@" >> "${basefolder}/${id}.running"
			fi
		}
		
		_lock_remove_waiting(){
			sed -i "/^${EUID} $$/d" "${basefolder}/${id}.waiting"
		}
		
		_lock_am_i_next(){
			[[ "$(head -n1 "${basefolder}/${id}.waiting")" =~ ^${EUID}" "$$ ]]
		}
		
		_lock_add_waiting(){
			if [[ $# -eq 0 ]]; then
				echo "${EUID} $$" >> "${basefolder}/${id}.waiting"
			else
				echo "${EUID} $$ $@" >> "${basefolder}/${id}.waiting"
			fi
		}
		
		_lock_remove_stalled(){
			local i j pid uid tmp array=()
			[[ -d "${basefolder}" ]] || return
			for i in "${basefolder}"/*.waiting "${basefolder}"/*.running; do
				[[ -f "${i}" ]] || continue
				readarray -t array < "${i}"
				for (( j=0; j<${#array[@]}; j++ )); do
					[[ "${array[$j]}" == "unnamed" ]] && continue
					[[ "${array[$j]}" =~ ^[0-9]+ ]] && uid=${BASH_REMATCH}; array[$j]="${array[j]/${uid} /}"
					[[ "${array[$j]}" =~ ^[0-9]+ ]] && pid=${BASH_REMATCH}
					if ! tmp=$(cat /proc/${pid}/loginuid >/dev/null 2>&1); then
						echo "Removing stalled ${uid} ${pid}."
						sed -i "/^${uid} ${pid}/d" "${i}"
					fi
				done
			done
		}
		
		_lock_lock(){
			if [[ $# -gt 0 ]]; then
				if ! which "${1}" >/dev/null; then
					echo "Error: command ${1} does not exist."
					exit 1
				fi
			fi
			_lock_sub_lock; _lock_add_waiting "$@"; _lock_sub_unlock
			_lock_wait "$@"
		}
		
		_lock_unlock(){
			_lock_sub_lock; _lock_remove_running_unnamed && ec=0 || ec=1; _lock_sub_unlock;
			return ${ec}
		}
		
		local sub_lock=0 ec found_free_slot=0 i id="${arguments[id]:-SomeRandomStringFoo123}"
		
		local basefolder="${arguments[path]:-/tmp/bashrclock.${EUID}}"
		mkdir -p ${basefolder} && chmod 0777 ${basefolder} 2>&1 >/dev/null || true
		[[ ! -w "${basefolder}" ]] && echo "Error: folder '${basefolder}' is not writable or does not exist." && exit 1
		
		for i in lock unlock get set list; do
			[[ ${arguments[${i}]:-0} -eq 1 ]] && mode=${i} && break
		done
		
		case ${mode} in
			lock)   _lock_lock "$@"; [[ $# -gt 0 ]] && exit $ec || true ;;
			unlock) _lock_unlock || exit 1;;
			get)    _lock_sub_lock; _lock_get_max "$@"; _lock_sub_unlock ;;
			set)    _lock_sub_lock; _lock_set_max "$@"; _lock_sub_unlock ;;
			list)   _lock_sub_lock; _lock_list "$@"; _lock_sub_unlock ;;
		esac
		exit $?
	}

	retention(){
		_binarysearch(){
			# Given an inputdate, returns "Value" like
			# date[value] <= inputDate
			# Example: _binarysearch 0 $(( $array - 1 )) 123
			local lowerIndex=${1} upperIndex=${2} value=${3} middle
			while [[ $lowerIndex -le $upperIndex ]]; do
				middle=$(( ( $upperIndex - $lowerIndex / 2) + $lowerIndex ))
				if [[ ${date[$middle]} -eq $value ]]; then
					echo $(( $middle )) && return 0
				else
					if [[ $value -lt ${date[middle]} ]]; then
						upperIndex=$(( $middle -1 ))
					else
						lowerIndex=$(( $middle +1 ))
					fi
				fi
			done
			echo -1 && return 0
		}
		
		_processInterval(){
			_processDay(){
				local localDate=${1} index=${2} i
				local indexTmp=$index localhour localmin mins myInterval intervalFound
				while [[ ${indexTmp} -ge 0 && ${indexTmp} -lt ${dates_counter} && ${date[$indexTmp]} -eq ${date[$index]} ]]; do
					lowIndex=${indexTmp}
					indexTmp=$(( ${indexTmp} - 1 ))
				done
				
				indexTmp=${index}
				while [[ ${indexTmp} -ge 0 && ${indexTmp} -lt ${dates_counter} && ${date[$indexTmp]} -eq ${date[$index]} ]]; do
					highIndex=$indexTmp
					indexTmp=$(( $indexTmp + 1 ))
				done
				
				# Example:
				# $lowIndex= 201301010000
				# $highIndex=201301012359
				local intervalMins=$(( 1440/${intervals} ))
				# echo "intervalMins: $intervalMins"
				for (( i=0; i<intervals; i++ )); do
					intervalFound[$i]=0
				done
				for (( i=$lowIndex; i<=$highIndex; i++  )); do
					localhour=$( echo ${hour[$i]:0:2} | sed 's/^0//' )
					localmin=$(  echo ${hour[$i]:2:2} | sed 's/^0//' )
					mins=$(( ($localhour * 60) + $localmin ))
					# Get in which interval this hour:minute is,
					# if it has not been found any prior hour:minute on this interval, mark the interval as found,
					# and mark this hour:minute not to be deleted
					myInterval=$(( $mins / $intervalMins))
					if [[ ${intervalFound[${myInterval}]} -eq 0 ]]; then
						intervalFound[${myInterval}]=1
						delete[$i]=0
					fi
					# echo "index: $i hora: $localhour:$localmin interval:$myInterval"
				done
			}
			
			# Search the oldest day in the given interval on the dates_in[] array
			dateIntervalStart=${1}
			interval_end=${2}
			intervals=${3}
			
			local i=${interval_end}
			local found=0
			while [[ $i -le $dateIntervalStart ]] && [[ $found -eq 0 ]]; do
				result=$(_binarysearch 0 $(( $dates_counter - 1 )) $i)
				if [[ $result -ne -1 ]]; then
					found=1
					_processDay $i $result
				fi
				i=$(( $i+1 ))
			done
		}
		arguments_list=(args1)
		args1='[print_pretty|print_dates] {retention} {dates}'
		arguments_description=( 'retention' 'Helper for keeping a specified retention with given dates.')
		arguments_parameters=( 'print_pretty: print all days with a mark "keep" or "delete".'
		                       'print_dates: print dates to be deleted.'
		                       '{retention}: retention to be used. Pairs of "days hours".'
		                       '{dates}: list of dates.' )
		arguments_examples=( '$ retention print_pretty "1 24   1 1  4 1" "200102040400 200102040300 200102040200 200102040100 200102030000 200102020000 200102010000 200101010000"' 'keep hourly copies for the first day, one copy for second day, and one copy for the interval of the following 4 days.' )
		argparse "$@" && shift ${arguments_shift}
		
		local -a dates=() retention_days=() retention_hours=() date=() hour=() delete=()
		local -i i j dates_counter
		local item
		for item in $(for item in ${arguments[dates]}; do echo "${item}"; done | sort); do
			[[ ! ${item} =~ ^[0-9]{12}$ ]] && echo "Error: date '${item}' is not valid." && exit 1 || true
			dates[${#dates[@]}]="${item}"
			date[${#date[@]}]="${item:0:8}"
			hour[${#hour[@]}]="${item:8:4}"
			delete[${#delete[@]}]=1
		done
		
		j=0; for item in ${arguments[retention]}; do
			is-number --message "${item}" || exit 1
			[[ $(( ${j} % 2 )) -eq 0 ]] && retention_days[${#retention_days[@]}]="${item}"
			[[ $(( ${j} % 2 )) -eq 1 ]] && retention_hours[${#retention_hours[@]}]="${item}"
			j=$(( $j + 1))
		done
		
		[[ $(( ${j} % 2 )) -eq 1 ]] && echo "Error in retention string." && exit 1
		
		dates_counter="${#dates[@]}"
		
		# Initialize end of interval to most recent day
		interval_end="${date[$(( $dates_counter - 1 ))]}"
		# Sustract one day to it
		interval_end="$(date -d "${interval_end} + 1 days" +'%Y%m%d')"
		
		# For every retention range
		for (( i=0; i<${#retention_days[@]}; i++ )); do
			# Start of interval is the prior day to the last day of last interval
			dateIntervalStart="$(date -d "${interval_end} - 1 days" +'%Y%m%d')"
			interval_end="$(date -d "${dateIntervalStart} - $(( ${retention_days[$i]} - 1 )) days" +'%Y%m%d')"
			# Search for the oldest day for this interval in the date[] array and mark them
			_processInterval $dateIntervalStart $interval_end ${retention_hours[$i]}
		done
		
		for (( i=0;i<$dates_counter;i++ )); do
			if [[ ${delete[$i]} -eq 0 ]]; then
				[[ ${arguments[print_pretty]:-0} -eq 1 ]] && echo "[keep]   ${dates[$i]}" || true
			else
				[[ ${arguments[print_pretty]:-0} -eq 1 ]] && echo "[delete] ${dates[$i]}" || printf "${dates[$i]} "
			fi
		done
		[[ ${arguments[print_pretty]:-0} -eq 1 ]] || printf "\n"
	}

	# lvmthinsnapshot(){
	# 	arguments_list=(args1); args1='{vg} {lv}'
	# 	arguments_description=( 'lvmthinsnapshot' 'Creates snapshots with custom retention.')
	# 	arguments_parameters=( '{name}: session name.' )
	# 	argparse "$@" && shift ${arguments_shift}
	# }

	status-changed(){
		arguments_list=(args1 args2)
		args1='set {id} {state} [-l|--last {last_state}] [intervals...]'
		args2='reset {id}'
		arguments_description=( 'lock' 'Locks the named identifier so other one trying to acquire a lock waits for it to be unlocked.')
		arguments_parameters=( '{id}: job identifier.'
		                       '{state}: current state (must be "ok" or "error").'
		                       '[-l|--last {last_state}]: if not last state was saved use this value (ok by default).'
		                       'reset {id}: removes last known state for the specified identifier.'
							   '[intervals...]: intervals between notifications, if no unit is used assume minutes (default 1m 15m 1h 1d)' )
		arguments_description=( 'status-changed'
		                        'Case scenario: do not send repeatedly emails when the problem has already been notified.'
		                        'If state is changed and new state is error, prints the date until no new notifications will be shown.'
		                        'If state is changed and new state is ok, prints the date the problem arised.'
		                        'Exit code 0: state has changed and based on intervals it should be notified.'
		                        'Exit code 1: state is unchanged.' )
		arguments_examples=( '$ status-changed reset raid_status' ''
		                     '$ foo && status-changed foo ok 1m 5m 15m 60m' ''
		                     '' ''
		                     '> some_command && ec=ok || ec=error' ''
		                     '> if next_date="$(status-changed some_tag ${ec} 5m 15m 1h)"; then' ''
		                     '>     [[ $ec == "ok"    ]] && echo "problem foo solved."' ''
		                     '>     [[ $ec == "error" ]] && echo "problem foo. No new emails noticing the problem will be sent until ${next_date}."' ''
		                     '> fi' )
		
		_status-changed_get_interval_get_accumulated(){
			# Returns the accumulated number of seconds for an interval
			local interval="${1}" i accumulated=0 interval_time last; shift
			for (( i=0; i<=${interval}; i++ )); do
				if [[ ${i} -lt ${#intervals[@]} ]]; then
					interval_time=${intervals[${i}]}
				else
					last=$(( ${#intervals[@]} - 1 ))
					interval_time=${intervals[${last}]}
				fi
				accumulated=$(( ${accumulated} + ${interval_time} ))
			done
			echo "${accumulated}"
		}
		
		_status-changed_get_interval(){
			# Return the interval a given date is in
			local change_date="$(date +%s --date "${previous_state[1]}")"
			local date="$(date +%s --date "${1}")"; shift
			
			local current_interval=0 accumulated
			while true; do
				accumulated=$(  _status-changed_get_interval_get_accumulated ${current_interval} )
				if [[ $(( ${date} - ${change_date}  )) -lt ${accumulated} ]]; then
					echo "${current_interval}"
					return
				fi
				current_interval=$(( ${current_interval} + 1 ))
			done
		}
		
		_status-changed_get_next_notify_time(){
			local next_interval_time
			next_interval_time="$( _status-changed_get_interval_get_accumulated ${current_interval} )"
			next_interval_time="$(( $(date --date "${previous_state[1]}" +%s ) + ${next_interval_time} ))"
			next_interval_time="$( date --date "@${next_interval_time}" +"%F %H:%M:%S" )"
			echo "${next_interval_time}"
		}
		
		_status-changed_save_to_disk(){
			local i first=1
			[[ -d "${folder}" ]] || mkdir -p "${folder}"
			while [[ $# -gt 0 ]]; do
				if [[ ${first} -eq 1 ]]; then
					echo "${1}" >  "${folder}/${arguments[id]}"
					first=0
				else
					echo "${1}" >> "${folder}/${arguments[id]}"
				fi
				shift
			done
		}
		
		argparse "$@" && shift ${arguments_shift}
		
		local folder="${HOME}/.local/share/status-changed" # Path where last state files are located
		# Reset
		if [[ "${arguments[reset]:-0}" -eq 1 ]]; then
			if [[ -f "${folder}/${arguments[id]}" ]]; then
				rm "${folder}/${arguments[id]}"; exit $?
			else
				exit 0
			fi
		fi
		
		local -i i; local -a intervals=()
		[[ $# -eq 0 ]] && intervals=(1m 15m 1h 1d) || intervals=("$@")
		for (( i=0; i<${#intervals[@]}; i++ )); do
			if ! check-type time "${intervals[$i]}"; then echo "Error with intervals, token '${intervals[$i]}' not valid time."; exit 1; fi
			intervals[$i]=$(unit-conversion time -d 0 s "${intervals[$i]}")
		done
		
		local previous_state_name
		local -a previous_state=()
		
		
		############################
		#### Get previous state ####
		############################
		if [[ -f "${folder}/${arguments[id]}" ]]; then
			readarray -t previous_state < "${folder}/${arguments[id]}"
			previous_state_name="${previous_state[0]}"
		else
			previous_state_name="${arguments[last_state]:-ok}"
			previous_state=( "${previous_state_name}" "$(date +'%F %H:%M:%S')" "$(date +'%F %H:%M:%S')" ${intervals[@]} )
		fi
		
		local state_name_check
		for state_name_check in "${arguments[state]}" "${previous_state_name}"; do
			if ! [[ "${state_name_check}" =~ ^ok|error$ ]]
			then
				echo "State string must be 'ok' or 'error'." && exit 1
			fi
		done
		
		local date="$(date +'%F %H:%M:%S')"
		local previous_interval="$( _status-changed_get_interval "${previous_state[2]}" )"
		local current_interval="$( _status-changed_get_interval "${date}" )"
		
		if [[ "${arguments[state]}" != "${previous_state_name}" ]]; then
			if [[ "${arguments[state]}" == "ok" ]]; then
				echo "${previous_state[1]}"
			else
				_status-changed_get_next_notify_time
			fi
			_status-changed_save_to_disk "${arguments[state]}" "${date}" "${date}" ${intervals[@]}
			exit 0
		elif [[ ${arguments[state]} == "error" ]]; then
			_status-changed_get_next_notify_time
			_status-changed_save_to_disk "${arguments[state]}" "${previous_state[1]}" "${date}" ${intervals[@]}
			[[ ${previous_interval} -lt ${current_interval} ]] && exit 0 || exit 1
		elif [[ ${arguments[state]} == "ok" ]]; then
			exit 1
		fi
	}

	rescan-scsi-bus(){
		arguments_list=(args1); args1=''
		arguments_description=( 'rescan-scsi-bus' 'Rescan the scsi bus')
		argparse "$@" && shift ${arguments_shift}
		local host
		for host in /sys/class/scsi_host/*; do
			[[ -d ${host} ]] && echo "- - -" > ${host}/scan
		done
	}

	tmuxac(){
		arguments_list=(args1); args1='{name}'
		arguments_description=( 'tmuxac' 'Attaches to the specified session or creates it')
		arguments_parameters=( '{name}: session name.' )
		argparse "$@" && shift ${arguments_shift}
		local i; local -a sessions
		readarray -t sessions < <(tmux ls 2>&1)
		for (( i=0; i<${#sessions[@]}; i++ )); do
			[[ "${sessions[$i]}" =~ ^${arguments[name]}: ]] && tmux attach-session -t "${arguments[name]}" && exit 0
		done
		tmux new-session -s "${arguments[name]}"
	}

	tmux-send(){
		arguments_list=(args1); args1='[-l|--loop [interval]] {target} {text...}'
		arguments_description=( 'tmux-send' 'Sends text to a tmux pane.')
		arguments_parameters=( '[-l|--loop [interval]]: executes in loop mode every [interval] seconds (by default 1 second).'
		                       '{target}: tmux pane.' '{text}: text to send.' )
		arguments_examples=( '$ tmux-send 2.1 ls C-m' '')
		argparse "$@" && shift ${arguments_shift}
		local -a params; local parameter
		for parameter in "$@"; do
			params[${#parameters[@]}]="${parameter}"
		done
		while true; do
			for (( i=0; i<${#params[@]}; i++ )); do
				if [[ "${params[$i]}" == "C-m" ]]; then
					tmux send-keys -t "${parameters[target]}" C-m
				else
					tmux send-keys -t "${parameters[target]}" "${params[$i]}"
					[[ $(( $i + 1 )) -lt ${#parameters[@]} ]] && tmux send-keys -t "${parameters[target]}" " "
				fi
			done
			[[ "${arguments[--loop]:-0}" -eq 1 ]] && sleep "${arguments[interval]:-1}" || break
		done
	}

	try(){
		arguments_list=(args1); args1='[-i|--interval {seconds}] {command...}'
		arguments_description=( 'try' 'Tries executing a command until it succeeds.')
		arguments_parameters=( '[-i|--interval {seconds}]: executes in loop mode every {seconds} (by default 1 second).' )
		arguments_examples=( '$ try ssh 1.2.3.4' 'keeps executing until it succeeds.')
		argparse "$@" && shift ${arguments_shift}
		if ! program-exists "${1}"; then
			echo "Program ${1} not found."; exit 1
		fi
		while true; do $@ && break; read -t ${arguments[seconds]:-1} || true; done
	}

	wait-ping(){
		arguments_list=(args1); args1='[-i|--interval {seconds}] {host}'
		arguments_description=( 'wait-ping' 'Wait until ping succeeds.')
		arguments_parameters=( '[-i|--interval {seconds}]: interval between tries (1 second by default).' )
		arguments_examples=( '$ wait-ping 1.2.3.4' 'keeps executing until it succeeds.')
		argparse "$@" && shift ${arguments_shift}
		program-exists ping || ( echo "ping program not found."; exit 1 )
		while true; do
			ping -c 1 -w 1 -q ${arguments[host]} >/dev/null 2>&1 && break
			read -t${arguments[interval]:-1} || true
		done
	}

	sshconnect(){
		arguments_list=(args1); args1='{parameters...}'
		arguments_description=( 'sshconnect' 'Executes ssh with ConnectTimeout=3 and ServerAliveInterval=3.')
		arguments_parameters=( '{parameters...}: parameters to pass to ssh.' )
		arguments_examples=( '$ sshconnect user@host' 'connect to user@host.')
		argparse "$@" && shift ${arguments_shift}
		ssh -o ConnectTimeout=1 -o ServerAliveInterval=3 $@
	}

	beep(){
		arguments_list=(args1); args1=''
		arguments_description=( 'beep' 'Beeps')
		argparse "$@" && shift ${arguments_shift}
		printf $'\a'
	}

	ssh-clean(){
		ssh-agent bash
		ssh-add $HOME/.ssh/id_rsa
	}

	max-mtu(){
		arguments_list=(args1); args1='[{mtu:integer}] {ip:ip}'
		arguments_description=( 'max-mtu' 'Obtain the maximum MTU to an IP.')
		arguments_parameters=( '[{mtu}]: start probing with this MTU (minimum value: 28).'
		                       '{ip}: test path to this IP.' )
		arguments_examples=( '$ max-mtu 9000 1.2.3.4' '')
		argparse "$@" && shift ${arguments_shift}
		
		local timeout=1 mtu
		local interface="$(ip -o route get ${arguments[ip]} | grep -o " dev .*" | sed -e 's/\s\+/ /g' -e 's/^ //' | cut -d' ' -f2)"
		if ! mtu="$(ip -o link show dev ${interface} 2>/dev/null)"; then
			echo "Error reading information from interface '$interface'.";
			exit 1
		fi
		mtu="$(echo "${mtu}" | awk '{print $5}')"
		
		if [[ ${arguments[mtu]:-0} -eq 0 || ${mtu} -lt ${arguments[mtu]:-0} ]]; then
			echo "Using MTU of ${mtu} from interface ${interface}."
		else
			if [[ ${arguments[mtu]} -lt 28 ]]; then
				echo "Using minimum MTU of 28."
				mtu=28
			else
				echo "Using MTU of ${arguments[mtu]}."
				mtu=${arguments[mtu]}
			fi
		fi
		
		while [[ ${mtu} -ge 28 ]]; do
			echo -ne "      \r${mtu}"
			ping -c 1 -W ${timeout} -w ${timeout} -M do -s $(( ${mtu} - 28 )) ${arguments[ip]} >/dev/null 2>&1 && break
			mtu=$(( ${mtu} - 1 ))
		done
		echo -ne "        \r"
		[[ ${mtu} -eq 27 ]] && echo "Did not get any ICMP reply from ${arguments[ip]}." && exit 1
		[[ ${mtu} -ge 28 ]] && echo "Maximum MTU found: ${mtu}."
	}

	pastebin(){
		arguments_list=(args1); args1='[files...]'
		arguments_description=( 'pastebin' 'Upload files to a test paste service.')
		arguments_parameters=( '[files...]: upload the specified files.' )
		arguments_examples=( '$ pastebin file1 file2' 'upload these two files'
		                     '$ echo "foo" | pastebin' 'upload the input text')
		_pastebin_print(){
			if [[ ${#url} -gt 0 ]]; then
				echo "$url"
				echo "To add syntax (for example bash): $url?bash"
			else
				echo "Error executing curl."; exit 1
			fi
		}
		argparse "$@" && shift ${arguments_shift}
		program-exists --message curl || exit 1
		if [[ -t 0 ]]; then
			[[ $# -eq 0 ]] && argparse_show_help 1
			while [[ $# -gt 0 ]]; do
				file-readable --message "${1}" || exit 1
				local url="$(curl -s -F 'sprunge=<-' http://sprunge.us < "${1}")"; shift
				_pastebin_print
			done
		else
			local url="$(curl -s -F 'sprunge=<-' http://sprunge.us < "/dev/stdin")"
			_pastebin_print
		fi
	}

	grepip(){
		arguments_list=(args1); args1='[-n|--name] [-o|--only] [files...]'
		arguments_description=( 'grepip' 'Print lines containng IPs. Reads from files or stdin')
		arguments_parameters=( '[-n|--name]: show file names.'
		                       '[-o|--only]: show only IPs instead of whole lines.')
		arguments_examples=( '$ grepip file1 file2' ''
		                     '$ echo 1.2.3.4 | grepip' '')
		argparse "$@" && shift ${arguments_shift}
		local params="" ec
		[[ ${arguments[-n]:-0} -eq 1 ]] && params="${params} -H"
		[[ ${arguments[-o]:-0} -eq 1 ]] && params="${params} -o"
		if [[ ! -t 0 ]]; then
			grep ${params} -E "${_ip_regex}" && local ec=0 || ec=1
		else
			ec=1
			while [[ $# -gt 0 ]]; do
				grep -E ${params} "${_ip_regex}" "${1}" && ec=0 || true
				shift
			done
		fi
		return $ec
	}

	repeat(){
		arguments_list=(args1); args1='[-s|--separator] [-d|--date] [-c|--clear] [-p|--pcommand] [{interval:time}] {command...}'
		arguments_description=( 'repeat' 'Execute a command continuously')
		arguments_parameters=( '[-s|--separator]: empty lines between executions.'
		                       '[-d|--date]: print date on every execution.'
		                       '[-c|--clear]: clear screen between executions.'
		                       '[-p|--pcommand]: print command being executed on every execution.'
		                       '{command...}: command to execute.'
		                       '{[interval]}: time interval between executions.')
		arguments_examples=( '$ repeat -d 5s ls -l' '' )
		argparse "$@" && shift ${arguments_shift}
		
		local interval
		interval=$(unit-conversion time -d 0 s "${arguments[interval]:-1s}")
		program-exists --message "${1}" || exit 1
		while true
		do
			[[ ${arguments[-c]:-0} -eq 1 ]] && clear
			local date="$(date +'%F %H:%M:%S')"
			[[ ${arguments[-d]:-0} -eq 1 || ${arguments[-p]:-0} -eq 1 ]] && color brown
			[[ ${arguments[-d]:-0} -eq 1 ]] && printf "${date}"
			[[ ${arguments[-d]:-0} -eq 1 && ${arguments[-p]:-0} -eq 1 ]] && printf ": "
			[[ ${arguments[-p]:-0} -eq 1 ]] && printf "$@"
			[[ ${arguments[-d]:-0} -eq 1 || ${arguments[-p]:-0} -eq 1 ]] && color && printf "\n"
			$@
			sleep ${interval}
			[[ ${arguments[-s]:-0} -eq 1 ]] && echo ""
			[[ ${arguments[-c]:-0} -eq 1 ]] && clear
		done
	}

	testcpu(){
		arguments_list=(args1); args1='[{iterations:integer}]'
		arguments_description=( 'testcpu' 'Executes a long math operation.')
		arguments_parameters=( '{[iterations]}: number of times to iterate.' )
		arguments_examples=( '$ testcpu 100' '' )
		argparse "$@" && shift ${arguments_shift}
		for (( i=0; i < ${arguments[iterations]:-1000000}; i++ ))
		do
			i=$(( $i+1))
		done
	}

	testport(){
		arguments_list=(args1); args1='[-m|--monitor [{interval:time}]] {host} {port}'
		arguments_description=( 'testport' 'Test if a TCP port is open')
		arguments_parameters=( '[-m|--monitor [{interval}]]: executes continuously.' )
		arguments_examples=( '$ testport -m 5s 1.2.3.4 80' '' )
		argparse "$@" && shift ${arguments_shift}
		local interval=$(unit-conversion time -d 0 s "${arguments[interval]:-1s}") pid
		if program-exists nc; then
			while true; do
				nc -z -w ${interval} ${arguments[host]} ${arguments[port]} && local ec=0 || local ec=1; exit $ec
				[[ ${arguments[-m]:-0} -eq 1 ]] || break
				if nc -z -w 1 ${arguments[host]} ${arguments[port]}; then
					printf "|"; read -t${interval} || break
				else
					printf "."; read -t${interval} || break
				fi
			done
		else
			while true; do
				bash -c "</dev/tcp/${arguments[host]}/${arguments[port]}" >/dev/null 2>&1 &
				pid=$!
				read -t${interval} || true
				pgrep -f -U ${EUID} -a "bash -c </dev/tcp/${arguments[host]}/${arguments[port]}$" && ec=1 && kill $pid || ec=0
				[[ ${arguments[-m]:-0} -eq 1 ]] || break
				if [[ ${ec} -eq 0 ]]; then
					printf "|"; read -t${interval} || break
				else
					printf "."; read -t${interval} || break
				fi
			done
		fi
	}

	timer-countdown(){
		arguments_list=(args1); args1='{times...}'
		arguments_description=( 'timer-countdown')
		arguments_parameters=( '{times...}: time for the count down.' )
		arguments_examples=( '$ timer-countdown 1h 30m 15s' '' )
		argparse "$@" && shift ${arguments_shift}
		local seconds=0 datenow timespec="$@"
		while [[ $# -gt 0 ]]; do seconds=$(( ${seconds} + $(unit-conversion time -d 0 s ${1}) )); shift; done
		local datenow="$(date +%s)"
		
		enddate="$(date --date="$seconds seconds" +%s)"
		printf "$(date -d @$(( $enddate - $datenow )) -u +'%H:%M:%S') [${timespec}]\n"
		
		_timer-countdown_print_remaining(){
			echo -ne "\r${ceol}"
			difference="$(date -d @$(( $enddate - $datenow )) -u +'%H:%M:%S')"
			printf "$difference"
		}
		
		ceol=`tput el`
		while [[ ${datenow} -lt ${enddate} ]]
		do
			_timer-countdown_print_remaining
			sleep 1
			datenow="$(date +%s)"
		done
		_timer-countdown_print_remaining
		printf "\n"
	}

	myip(){
		arguments_list=(args1); args1='[-m|--monitor [{interval:time}]] [commands...]'
		arguments_description=( 'myip' 'Shows the public IP.')
		arguments_parameters=( '[-m|--monitor [{interval}]]: monitor mode, notice when IP public changes.'
		                       '[-c|--command {commands...}]: execute a command every time the public IP changes (only applicable to monitor mode).' )
		argparse "$@" && shift ${arguments_shift}
		program-exists --message wget || exit 1
		local -a urls=(http://www.amospalla.es/ip/ http://ipecho.net/ http://ip.pla1.net http://checkip.dyndns.org http://myip.dnsdynamic.org http://ifconfig.co)
		local interval=$(unit-conversion time -d 0 s ${arguments[interval]:-1m})
		
		_myip_query(){
			wget -q -T 5 "${1}" -O - | grepip -o
		}
		
		_myip_get_ip(){
			local url
			for url in ${urls[@]}; do
				_myip_query ${url} && return
			done
		}
		
		if [[ ${arguments[-m]:-0} -eq 0 ]]; then
			_myip_get_ip
		else
			while true; do
				if newip="$(_myip_get_ip)" && [[ ! ${oldip:-None} == ${newip} ]]; then
					printf "$(date +"%F %H:%M:%S") ${newip}\n"
					oldip=${newip}
					[[ $# -gt 0 ]] && $@
				fi
				sleep ${interval}
			done
		fi
	}
}

#====================================================================
# Bash Histgrep
#====================================================================

_source_histgrep(){
	histgrep() {
		grep --color -h "${*}" "${path}"/*
	}
	
	histlast() {
		# prints last command
		grep --color -h "${*}" "${path}"/* | grep -E -v "^.{21}hist.*"| tail -n1
	}
	
	histrun() {
		# executes last command
		[[ -z "$1" ]] && printf "need parameter\n" && return 1
		local command="$(histlast "$1")"
		command=${command:21}
		echo "[Executing] $command"
		eval "$command"
	}

	# ignore history duplicates
	export HISTCONTROL=ignoredups
	# add date/time to history output
	export HISTTIMEFORMAT='%F %H.%M.%S '
	# append history, do not overwrite
	shopt -s histappend
	# check the window size after each command and, if necessary, update the values
	# of LINES and COLUMNS.
	shopt -s checkwinsize
	# Send SIGHUP to all jobs when exit from interactive shell
	# shopt -s huponexit
	# Don't write commands starting with space on history (ie: " ls")
	export HISTCONTROL=ignorespace
	
	path="${HOME}/.history"
	export HISTTIMEFORMAT='%F %H.%M.%S ' # history format: "  {history_num}  2013-06-15 13.00.43 {command}"
	_histgrep_new_history=0
	_histgrep_ssh_canard=0
	_tty=$(tty | sed -e "s/\/dev\///" -e "s/\///" -e "s/not a tty/notatty/")
	_histgrep_filename="$(date +"%Y%m%d%H%M%S").$$.${_tty}" # 20130615125716.nanoseconds.pts18
	_histgrep_file="${path}/${_histgrep_filename}" # /home/user/.history/20130615125716pts18
	
	# Detect new command being written, through PROMPT_COMMAND, used in save history
	# With true time diff between commands is achieved as it makes ps1_date_old
	# evaluated just before real command is executed
	PROMPT_COMMAND="true; _histgrep_new_history=1; _bash_reload; $PROMPT_COMMAND"
	
	[[ -d "${path}" ]] || mkdir "${path}"
	
	local oldpath="${HOME}/.historial"
	# Move old folder $HOME/.historial to $HOME/.history
	[[ -d "${oldpath}" ]] && find "${oldpath}" -maxdepth 1 -regextype posix-basic -regex "${oldpath}/\([0-9]\{8\}\|[0-9]\{14\}\..*\)$" && mv "${oldpath}" "${path}"

	_history_compact(){
		# Compact several history files with a common day
		echo "Compacting history files ..."
		# Find files named like 20130915165548.526607.pts12, and remove trailing PID.pts*, and hour (H:M:S)
		# Get days only from those, ie: 20010707
		local days_temp days=()
		days_temp="$(find "${path}" -regextype grep -type f -regex ".*/[0-9]\{14\}\.[0-9]*\.\(pts\|tty\)[0-9]*" | sed -e 's/[0-9]\{6\}\.[0-9]*\.\(pts\|tty\)[0-9]*//' -e "s;${path}/;;" | sort | uniq)"
		readarray -t days < <(echo "${days_temp}")
		
		# For every day, found, check if all their files have no corresponding bash process, and compact
		# ie: /home/user/.history/20130915
		local i file files=() pid
		for (( i=0; i<${#days[@]}; i++ )); do
			for file in "${path}/${days[$i]}"*; do
				[[ ${file} =~ \.[0-9]+\. ]] && [[ ${BASH_REMATCH} =~ [0-9]+ ]] && pid=${BASH_REMATCH}
				[[ -f /proc/${pid}/loginuid && $(cat /proc/${pid}/loginuid) -eq $EUID && $(cat /proc/${pid}/cmdline) =~ -?bash ]] && continue 2
			done
			
			echo "Compacting ${days[$i]}"
			
			while read -r file; do
				# Cat file basename
				echo "$(basename "${file}") >>>>>>>>>>>>>>>>>>>>>>>" >> "${path}/${days[$i]}"
				cat ${file} >> "${path}/${days[$i]}"
				rm ${file}
			done < <(find ${path} -type f -regextype sed -regex "${path}/${days[$i]}[0-9]\{6\}\.[0-9]*\.\(pts\|tty\)[0-9]*" | sort)
		done
	}

	preexec(){
		# PROMPT_COMMAND is evaluated before showing prompt
		# http://unix.stackexchange.com/q/44713
		
		# don't do anything until PROMPT_COMMAND sets _histgrep_new_history to 1
		[[ ${_histgrep_new_history} -eq 0 ]] && return
		
		# ignore setting _histgrep_new_history=1
		[[ "$BASH_COMMAND" = "_histgrep_new_history=1" ]] && return
		
		local new_history="$(history 1)"
		
		if [[ ! "$OLD_HISTORY" = "${new_history}" ]]; then
			# Get ssh information if not retrieved before
			if [[ ${_histgrep_ssh_canard} -eq 0 ]]; then
				_histgrep_ssh_canard=1
				if [[ -n "$SSH_CLIENT" ]]; then
					if program-exists host && ssh_client="$(host -W 1 $(echo $SSH_CLIENT | awk '{print $1}') 2>/dev/null)"; then
						true
					else
						ssh_client=no_reverse_dns_information
					fi
					if [[ "$ssh_client" = "no_reverse_dns_information" ]]; then
						echo "         ssh_client  ${SSH_CLIENT}" >> "${_histgrep_file}"
					else
						echo "         ssh_client  ${SSH_CLIENT}, reverse_dns ${ssh_client}" >> "${_histgrep_file}"
					fi
				fi
			fi
			local history1="$(date +"%F %H.%M.%S")"
			local history2="$(echo "${new_history}" | sed 's/^\s*[0-9]*[0-9. -]\{21\}//')"
			echo "${history1} ${history2}" >> "${_histgrep_file}"
			OLD_HISTORY=${new_history}
		fi
		if [[ -z "$ps1_date_new" ]]
		then
			export ps1_date_new="$(date +'%s')"
			export ps1_date_old="$ps1_date_new"
		else
			export ps1_date_old="$ps1_date_new"
			export ps1_date_new="$(date +'%s')"
		fi
		ps1_time_diff="$(( $ps1_date_new - $ps1_date_old))"
	}

	# Compact history every now and then
	[[ ${_histgrep_compact} -eq 1 ]] && [[ $(($RANDOM % 50)) -eq 0 ]] && _history_compact
	
	trap 'preexec' DEBUG
}

#====================================================================
# Prompt
#====================================================================

_source_ps1(){
	color_host=$color_greenb
	color_load_high="$color_redb"
	color_chroot=$color_yellowb
	color_custom_1=$color_yellowb
	color_venv=$color_gray9
	color_git=$color_gray9
	color_git_clean=$color_greenb
	color_git_staged=$color_pinkb
	color_git_unstaged=$color_pinkb
	color_at=$color_white
	color_path_read=$color_cyanb
	color_path_write=$color_yellowb
	color_normal=$color_gray
	color_tag=$color_blueb
	color_jobs=$color_pinkb
	color_error=$color_redb
	color_disabled=$color_gray9
	color_tmux_bracket=$color_blueb
	color_enabled=$color_yellow_bright

	color_default="$color_gray"

	export ps1_date_new="$(date +'%s')"
	[[ ${_ps1_get_performance} -eq 1 ]] && _abpp=()

	_ps1_perf_end(){
		_abpp[${1}]=$( perf_end ${1} )
		if [[ ${2:-0} == "first" ]]; then
			echo "${1}: ${_abpp[${1}]}" > "${_ps1_performance_file}"
		else
			echo "${1}: ${_abpp[${1}]}" >> "${_ps1_performance_file}"
		fi
	}

	if [[ "${_ps1_enable:-0}" -eq 1 ]]; then
	export PS1='`
		exit_code=$?
		ps1_separator=0

		print_separator(){
			[[ "${ps1_separator}" -eq 1 ]] && printf " " && ps1_separator=0
		}
		_color(){
			_color_force=1
			printf "\["; color ${1}; printf "\]"
			_color_force=0
		}

		########
		# tmux #
		########
		#a⊞a⊡a⌹a⑄a◫a⬚a
		if [[ "${_ps1_tmux}" -eq 1 ]]
		then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start tmux
			[[ -n "${TMUX:-}" || -n "${STY:-}" ]] && inside_tmux=1 || inside_tmux=0
			tmux_sessions="$(tmux ls 2>/dev/null | wc -l)"
			screen_sessions="$(screen -ls 2>/dev/null| grep "Attached\|Detached" | wc -l)"
			total_sessions="$(( $tmux_sessions + screen_sessions ))"
			
			if [[ ${inside_tmux} -eq 1 ]]; then
				_color blue; printf "["
			fi
			if [[ $total_sessions -gt 0 ]]; then
				# printf "\[${color_enabled}\]⑄"
				_color boldyellow; printf "T"
				ps1_separator=1
			fi
			if [[ $inside_tmux -eq 1 ]]; then
				_color blue; printf "]"
			fi
			print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end tmux first
		fi

		###############
		# x11 display #
		###############
		if [[ "${_ps1_x11_display}" -eq 1 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start x11
			if [[ -n "${DISPLAY}" ]] && xhost +si:localuser:$USER >&/dev/null; then
				_color boldyellow; printf "X"
				ps1_separator=1 && print_separator
			fi
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end x11
		fi

		########
		# time #
		########
		if [[ "${_ps1_time}" -eq 1 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start time
			_color
			echo -n "$(date +"%d")/\t"
			[[  "${ps1_time_diff}" =~ [0-9]+ ]] || ps1_time_diff=0
			if [[ ${ps1_time_diff} -eq 0 ]]; then
				_color boldblack; printf " %3d" ${ps1_time_diff}
			elif [[ ${ps1_time_diff} -le 5 ]]; then
				_color; printf " %3d" ${ps1_time_diff}
			elif [[ ${ps1_time_diff} -gt 5 ]]; then
				_color white; printf " %3d" ${ps1_time_diff}
			fi
			ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end time
		fi

		########
		# load #
		########
		if [[ "${_ps1_load}" -eq 1 ]]; then
			# [[ ${_ps1_get_performance} -eq 1 ]] && perf_start load
			loadavg="$(</proc/loadavg)"
			while true; do
				load="${load:-}${loadavg:0:1}"
				loadavg=${loadavg:1}
				[[ ${loadavg:0:1} != . ]] && load="${load}${loadavg:0:2}" && break
			done
			
			if [[ ${load:0:1} -eq 0 ]]; then
				_color; printf "%.1f" ${load}
			else
				_color red; printf "%.1f" ${load}
			fi
			readarray -t cpu_sockets_in < /proc/cpuinfo
			cpu_sockets=1
			cpu_cores_per_socket=0
			for (( i=0; i<${#cpu_sockets_in[@]}; i++ )); do
				[[ ${cpu_sockets_in[$i]} =~ ^physical" "id" ".*:" "[0-9]+ ]] && [[ ${BASH_REMATCH} =~ [0-9]+ ]] && cpu_socket=${BASH_REMATCH}
				[[ ${cpu_socket:-0} -gt cpu_sockets ]] && cpu_sockets=${cpu_socket}
				[[ ${cpu_sockets_in[$i]} =~ core" "id ]] && cpu_cores_per_socket=$(( ${cpu_cores_per_socket} + 1 ))
			done
			
			[[ ${cpu_cores_per_socket} -eq 0 ]] && cpu_cores_per_socket=1
			ps1_num_cores="$(( ${cpu_sockets} * ${cpu_cores_per_socket} ))"
			_color; printf "/"
			if [[ ${load:0:1} -ge ${ps1_num_cores} ]]; then
				_color red; printf "${ps1_num_cores}"
			else
				_color; printf "${ps1_num_cores}"
			fi
			ps1_separator=1 && print_separator
			# [[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end load
		fi

		#######
		# tag #
		#######
		if [[ "${_ps1_tag}" -eq 1 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start tag
			for i in tag tag1 tag2 tag3 tag4 tag5 tag6; do
				if [[ "${!i}" ]]; then
					_color boldmagenta; printf "(${!i})"
					ps1_separator=1 && print_separator
					_color
				fi
			done
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end tag
		fi

		############
		# custom 1 #
		############
		if [[ -n "${ps1_custom_1:-}" ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start custom1
			_color boldmagenta; printf "[${ps1_custom_1}]"
			ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end custom1
		fi

		###############
		# chroot name #
		###############
		if [[ "${_ps1_chroot_name}" -eq 1 && -n "${chroot_name:-}" ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start chrootname
			_color boldmagenta; printf "[chroot:${chroot_name}]"
			ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end chrootname
		fi

		########
		# jobs #
		########
		if [[ "${_ps1_jobs}" -eq 1 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start jobs
			readarray -t _ps1_jobs < <(jobs 2>/dev/null)
			if [[ "${#_ps1_jobs[@]}" -gt 0 ]]; then
				#a↓a↡a↧a↺a↻a⇩a⟲a⟳a⥀a⥁a⬇a
				# ababababababababababa
				ps1_jobs_running=0
				ps1_jobs_stopped=0
				for (( i=0; i<${#_ps1_jobs[@]}; i++ )); do
					[[ "${_ps1_jobs[$i]}" =~ Running ]] && ps1_jobs_running=$(( ${ps1_jobs_running} + 1 ))
					[[ "${_ps1_jobs[$i]}" =~ Stopped ]] && ps1_jobs_stopped=$(( ${ps1_jobs_stopped} + 1 ))
				done
				_color boldmagenta
				if [[ ${ps1_jobs_running} -gt 0 ]]; then
					printf "&R${ps1_jobs_running}"
					if [[ ${ps1_jobs_stopped} -gt 0 ]]; then
						printf "S${ps1_jobs_stopped}"
					fi
					ps1_separator=1
				elif [[ ${ps1_jobs_stopped} -gt 0 ]]; then
					printf "&S${ps1_jobs_stopped}"
					ps1_separator=1
				fi
			fi
			print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end jobs
		fi

		########################
		# user_at_hostname:pwd #
		########################
		if [[ "${_ps1_user_at_host}" -eq 1 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start userathost
			# _color
			# user               -> green
			# root               -> red
			# user != login user -> blue
			
			if [[ ${_tty} =~ ^tty[0-9]+$ ]]; then
				[[ ! -O "/dev/${_tty}" ]] && user_not_owns_terminal=true || unset user_not_owns_terminal
			elif [[ ${_tty} =~ ^pts[0-9]+$ ]]; then
				[[ "${_tty}" =~ [0-9]+ ]]
				[[ ! -O "/dev/pts/${BASH_REMATCH}" ]] && user_not_owns_terminal=true || unset user_not_owns_terminal
			fi
			
			[[ -n ${user_not_owns_terminal:-} ]] && _color boldblue && printf "["
			
			if [[ ${EUID} -eq 0 ]]; then
				_color boldred; printf "root"
			else
				_color boldgreen; printf "\u"
			fi
			[[ -n ${user_not_owns_terminal:-} ]] && _color boldblue && printf "]"
			
			_color white; printf "@"
			
			[[ -n "${SSH_CLIENT:-}" ]] && _color boldblue || _color boldgreen
			printf "\h"
			
			_color white; printf ":"
			
			if [[ -w . ]]; then
				_color boldyellow
			else
				_color cyan
			fi
			echo -n "\w"
			ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end userathost
		fi

		##############
		# virtualenv #
		##############
		if [[ "${_ps1_virtualenv}" -eq 1 && -n "${VIRTUAL_ENV:-}" ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start virtualenv
			_color green; printf "[v:$(printf ${VIRTUAL_ENV} | sed "s;.*/;;")]"
			ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end virtualenv
		fi

		#######
		# git #
		#######
		if [[ "${_ps1_git}" -eq 1 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start git
			lookat="."
			path="$PWD/"
			for ((i=0;i<${#path};i++)); do
				if [[ ${path:$i:1} = '/' ]]; then
					if [[ -d "$lookat/.git" ]]; then
						git_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
						break
					fi
					lookat="$lookat/.."
				fi
			done
			
			if [[ -n "${git_branch:-}" ]]; then
				ps1_separator=1
				[[ "${git_branch}" = "HEAD" ]] && git_branch="detached"
				_color blue; printf "["
				if readarray git_status < <(git status -s 2>/dev/null); then
					clean=1
					unstaged=0
					staged=0
					[[ "${git_status[@]}" =~ " M " ]] && unstaged=1 && clean=0
					[[ "${git_status[@]}" =~ "?? " ]] && unstaged=1 && clean=0
					[[ "${git_status[@]}" =~ "A  " ]] &&   staged=1 && clean=0
					[[ "${git_status[@]}" =~ "D  " ]] &&   staged=1 && clean=0
					[[ "${git_status[@]}" =~ "R  " ]] &&   staged=1 && clean=0
					[[ ${clean}    -eq 1 ]] && _color boldgreen; printf "C"
					[[ ${staged}   -eq 1 ]] && _color boldred; printf "S"
					[[ ${unstaged} -eq 1 ]] && _color boldred; printf "U"
				fi
				_color blue; printf " ${git_branch}]"
			fi
			print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end git
		fi

		###############
		# bash update #
		###############

		if [[ "${_ps1_bash_update}" -eq 1 ]]; then
			[[ ${_ps2_get_performance} -eq 1 ]] && perf_start bashupdate
			if [[ ${_bash_updated} -eq 1 ]]; then
				_color magentabold; printf "(bashrc updated: ${FileVersionOld} > ${FileVersion})"
				ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end bashupdate
			fi
		fi

		#############
		# exit code #
		#############
		if [[ "${_ps1_exit_code}" -eq 1 && "${exit_code}" -gt 0 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start exitcode
			# printf "\[${color_error}\]${exit_code} ↯"
			_color boldred; printf "(${exit_code})"
			[[ ${_ps1_prompt} -eq 1 ]] && ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end exitcode
		fi

		##########
		# prompt #
		##########
		if [[ "${_ps1_prompt}" -eq 1 ]]; then
			[[ ${_ps1_get_performance} -eq 1 ]] && perf_start prompt
			if [[ ${EUID} -eq 0 ]]; then
				_color boldred; printf "\$"
			else
				_color boldgreen; printf "\$"
			fi
			ps1_separator=1 && print_separator
			[[ ${_ps1_get_performance} -eq 1 ]] && _ps1_perf_end prompt
		fi

		_color
	`'
	fi
}

#====================================================================
# Programs
#====================================================================

_program_list=(try sshconnect make-links myip status-changed rescan-scsi-bus timer-countdown tmuxac wait-ping grepip tmux-send is-number beep max-mtu repeat testcpu testport pastebin lock extract disksinfo color lowercase uppercase check-type argparse argparse-create-template unit-conversion unit-print float retention check-ping check--usage)

make-links(){
	_show_help(){
		echo "Usage: "
		color blue; printf "  make-links "; color green; printf "[-h]"; color red; printf " {path}\n"; color
		color blue; printf "  make-links "; color green; printf "[-h]"; color red; printf " --system-wide\n\n"; color
		echo "Parameters:"
		color blue; printf -- "           [-h]"; color; echo ": show this help."
		color blue; printf -- "         {path}"; color; echo ": folder where to create links."
		color blue; printf -- "  --system-wide"; color; echo ": make programs available to all users."
		printf "\nCreates links to bashrc programs into specified folder (HOME/bin if none specified).\n"
		printf "When using the system-wide option, copy source file and generate links on /usr/local/bin.\n"
	}
	
	[[ "${1:-}" == "-h" ]] && _show_help && return 0
	
	if [[ -f "${0}" ]]; then
		local source="${0}"
	else
		local source="${HOME}/.bashrc"
	fi
	
	local source="$(readlink -f ${source})"
	
	local destination_folder="${1:-${HOME}/bin}"
	if [[ "${destination_folder}" == "--system-wide" ]]; then
		destination_folder=/usr/local/bin
		if [[ -w "${destination_folder}" ]]; then
			cp "${source}" "${destination_folder}/bashrc" && chmod 0755 "${destination_folder}/bashrc"
			"${destination_folder}/bashrc" make-links "${destination_folder}"
			return $? 2>/dev/null || exit $?
		else
			echo "Error: /usr/local/bin folder is not writeable."
			return $? 1>/dev/null || exit 1
		fi
	fi
	
	[[ ! -d "${destination_folder}" ]] && echo "Error, specified path does not exist." && return 1
	
	echo "Source: ${source}, destination: ${destination_folder}"
	local program
	local source_old
	# add links
	for program in ${_program_list[@]}; do
		if [[ -f "${destination_folder}/${program}" || -L "${destination_folder}/${program}" ]]; then
			source_old="$(readlink -f "${destination_folder}/${program}")"
			printf "[already present] ${program}"
			if [[ "${source_old}" == "${source}" ]]; then
				printf "\n"
			else
				if [[ -L "${destination_folder}/${program}" ]]; then
					printf "  (linked from ${source_old})"
				else
					printf "  (independent binary)"
				fi
				printf "\n"
			fi
		else
			echo "[new]             ${program}"
			ln -s "${source}" "${destination_folder}/${program}"
		fi
	done
	
	# remove old links
	local link found
	find "${destination_folder}" -type l | while read link; do
		[[ "$(readlink -f "${link}")" == "${source}" ]] || continue
		found=0
		for program in ${_program_list[@]}; do
			[[ "$(basename ${link})" == "${program}" ]] && found=1 && break
		done
		[[ ${found} -eq 0 ]] && echo "[remove old]      $(basename "${link}")" && rm "${link}"
	done
	# [[ ${EUID} -eq 0 && "${destination_folder}" != "system-wide" ]] && echo "" && make-links --system-wide || true
}

#====================================================================
# Main
#====================================================================
_main "$@"
