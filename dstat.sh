#!/bin/bash

# TODO: add rbd with find /dev/rbd

# FileVersion=1

set -eu -o pipefail -o errtrace

declare -i counter=0 disk_total=0 disk_start=0 network_total=0 network_start=0 disk_selected=0 network_selected=0
declare -A disk=() network=() selected=() disk_short=() disk_real=()
declare -a network_ignore=( "lo" )
declare -a disk_ignore=( "/dev/mapper/control" "/dev/mapper/.*_tdata" "/dev/mapper/.*_tmeta" "/dev/mapper/.*-tpool" "/dev/mapper/.*thinpool[0-9]+" "/dev/mapper/.*-real" "/dev/mapper/.*-cow")

# Read Disk
for dev in $(echo /dev/sd* /dev/vd* /dev/xvd* /dev/hd* /dev/mapper/* /dev/md/*| sort -g) total; do
	[[ ${dev} =~ "*" ]] && continue
	for (( i=0; i<${#disk_ignore[@]}; i++ )); do
		[[ ${dev} =~ ^${disk_ignore[$i]}$ ]] && continue 2
	done
	counter=$(( counter + 1))
	disk[${counter}]="${dev}"
	disk_short[${counter}]="$(basename "${dev}")"
	disk_real[${counter}]="$( basename "$( readlink -f "${dev}")")"
	[[ ${disk_start} -eq 0 ]] && disk_start=$(( counter ))
	disk_total=$(( disk_total + 1 ))
	selected[${counter}]=0
done

# Read Network
for dev in $(ip link show up | grep "^[0-9]" | sed -e 's/^[0-9]\+: //' -e 's/:.*//' -e 's/@if[0-9]\+//'| sort -g) total; do
	for (( i=0; i<${#network_ignore[@]}; i++ )); do
		[[ ${dev} =~ ^${network_ignore[$i]}$ ]] && continue 2
	done
	counter=$(( counter + 1))
	[[ ${network_start} -eq 0 ]] && network_start=$(( counter ))
	network[${counter}]="${dev}"
	network_total=$(( network_total + 1 ))
	selected[${counter}]=0
done

# Menu
while "true"; do
	clear
	print-color boldblue "Block devices:\n"
	for (( i=$(( disk_start)); i<$((disk_start + disk_total)); i++ )); do
		if [[ ${selected[${i}]} -eq 1 ]]; then
			print-color red "$( printf "  %3d)" ${i}; [[ ${disk_real[$i]} == ${disk_short[$i]} ]] || printf " %5s" ${disk_real[$i]}
			printf " ${disk[$i]}")\n"
		else
			printf "  %3d)" ${i}; [[ ${disk_real[$i]} == ${disk_short[$i]} ]] || printf " %5s" ${disk_real[$i]}
			printf " ${disk[$i]}\n"
		fi
	done

	echo ""
	print-color boldblue "Network devices:\n"
	for (( i=$(( network_start )); i<$(( network_start + network_total )); i++ )); do
		if [[ ${selected[${i}]} -eq 1 ]]; then
			print-color red "  %3d) ${network[$i]}\n" ${i}
		else
			printf "  %3d) ${network[$i]}\n" ${i}
		fi
	done

	echo ""
	print-color boldblue "Actions:\n"
	echo "0-9*) select/unselect"
	echo "   l) load"
	echo "   s) save"
	echo "   c) continue"
	read next; printf "\n"
	case "${next}" in
		l)
			echo stub load
			;;
		s)
			echo stub save
			;;
		c)
			break
			;;
		0*|1*|2*|3*|4*|5*|6*|7*|8*|9*)
			[[ ${next} =~ ^[0-9]+$ ]] || continue
			if [[ ${next} -ge ${disk_start} && ${next} -lt $(( disk_start + disk_total )) ]]; then
				if [[ selected[${next}] -eq 0 ]]; then
					selected[${next}]=1 && disk_selected=$(( disk_selected + 1 ))
				else
					selected[${next}]=0 && disk_selected=$(( disk_selected - 1 ))
				fi
			fi
			if [[ ${next} -ge ${network_start} && ${next} -lt $(( network_start + network_total )) ]]; then
				if [[ selected[${next}] -eq 0 ]]; then
					selected[${next}]=1 && network_selected=$(( network_selected + 1 ))
				else
					selected[${next}]=0 && network_selected=$(( network_selected - 1 ))
				fi
			fi
			;;
	esac
done

disks=""
for (( i=$(( disk_start)); i<$((disk_start + disk_total)); i++ )); do
	[[ ${selected[${i}]} -eq 1 ]] && disks="${disks},${disk_real[$i]}"
done
disks="$(echo "${disks}" | sed -e 's/\/dev\///g' -e 's/^,//')"

networks=""
for (( i=$(( network_start)); i<$((network_start + network_total)); i++ )); do
	[[ ${selected[${i}]} -eq 1 ]] && networks="${networks},${network[$i]}"
done
networks="$(echo "${networks}" | sed -e 's/^,//')"

opts=""
if [[ ${disk_selected} -gt 0 ]]; then
	opts="${opts} -D ${disks} --disk --io"
else
	opts="${opts} -D total --disk --io"
fi

if [[ ${network_selected} -gt 0 ]]; then
	opts="${opts} -N ${networks} --net"
else
	opts="${opts} -N total --net"
fi

dstat -c ${opts} -gy
