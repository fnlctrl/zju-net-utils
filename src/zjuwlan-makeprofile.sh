#!/bin/bash
#
# zjuwlan.sh: Script for generating netctl profile for ZJUWLAN
#
# Copyright (c) 2014 Zhang Hai <Dreaming.in.Code.ZH@Gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
#

PROFILE_NAME_DEFAULT=wireless-zju

name=$(basename "$0")
overwrite=0
interface=
profile_name=${PROFILE_NAME_DEFAULT}
profile_path=

usage() {
    cat <<EOF
Usage: ${name} [OPTIONS] [PROFILE_NAME]

Options:
  -h, --help            Display this help and exit
  -i, --interface=NAME  Use NAME as wireless interface in generated netctl
                        profile; if not specified, the interface is assumed to
                        be the result of \$(ls /sys/class/net | grep 'wl' |
                        head -n1), which is $(ls /sys/class/net | grep 'wl' | head -n1) now.
  -y, --overwrite       Overwrite existing profile without prompting, if any

With no PROFILE_NAME, Default profile name ${PROFILE_NAME_DEFAULT} is used.
EOF
}

parse_args() {

    local args
    args=$(getopt -o hy -l help,overwirte -n "${name}" -- "$@")
    if [[ $? != 0 ]]; then
        exit 1
    fi

    eval set -- "${args}"
    while :; do
        case "$1" in
            -h|--help)
                shift
                usage
                exit
                ;;
            -i|--interface)
                shift
                interface="$1"
                shift
                ;;
            -y|--overwrite)
                shift
                overwrite=1
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    if [[ -z "${interface}" ]]; then
        interface="$(ls /sys/class/net | grep 'wl' | head -n1)"
        if [[ -n "${interface}" ]]; then
            echo "Detected wireless interface ${interface}"
        else
            echo "Unable to detect a wireless interface" >&2
            exit 1
        fi
    fi

    if [[ $# -gt 0 ]]; then
        profile_name="$1"
        shift
    fi

    profile_path="/etc/netctl/${profile_name}"

    if [[ $# -gt 0 ]]; then
        echo "Unknown argument: $@" >&2
        echo >&2
        usage >&2
        exit 1
    fi
}

prepare_sudo() {
    sudo -v
}

check_exist() {
    if [[ ${overwrite} -ne 0 ]]; then
        return
    fi
    if [[ -e "${profile_path}" ]]; then
        echo -n "Profile ${profile_name} already exists. Overwrite? (Y/n): "
        local choice
        read choice
        if [[ "${choice}" != "Y" ]] && [[ "${choice}" != "y" ]]; then
            exit 0
        fi
    fi
}

write_profile() {
    sudo tee "${profile_path}" >/dev/null <<EOF && echo "Profile ${profile_name} created successfully."
Description='Wireless connection for ZJUWLAN'
Interface=${interface}
Connection=wireless
Security=none
ESSID='ZJUWLAN'
IP=dhcp
ExecUpPost=zjuwlan-login || true
EOF
}

main() {
    parse_args "$@"
    prepare_sudo
    check_exist
    write_profile
}

main "$@"
