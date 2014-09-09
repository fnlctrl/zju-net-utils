#!/bin/bash
#
# zjuwlan.sh: Script for ZJUWLAN login
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

name=$(basename "$0")
force=1
log_out=0
username=
password=

usage() {
    cat <<EOF
Usage: ${name} [OPTIONS] [USERNAME] [PASSWORD]

Options:
  -h, --help        Display this help and exit
  -n, --no-force    Do not kick other clients offline before logging in
  -o, --log-out     Log out from ZJUWLAN

With no USERNAME or PASSWORD, read standard input.
EOF
}

parse_args() {

    local args
    args=$(getopt -o hno -l help,no-force,log-out -n "${name}" -- "$@")
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
            -n|--no-force)
                shift
                force=0
                ;;
            -o|--log-out)
                shift
                log_out=1
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    if [[ $# -gt 0 ]]; then
        username="$1"
        shift
    else
        read -p "Username: " username
    fi

    if [[ $# -gt 0 ]]; then
        password="$1"
        shift
    else
        read -p "Password: " -s password
        echo
    fi

    if [[ $# -gt 0 ]]; then
        echo "Unknown argument: $@" >&2
        echo >&2
        usage >&2
        exit 1
    fi
}

do_log_out() {
    local response
    response=$(curl "https://net.zju.edu.cn/rad_online.php" -H "Content-Type: application/x-www-form-urlencoded" -d "action=auto_dm&username=${username}&password=${password}" -s)
    if [[ "${response}" != "ok" ]]; then
        echo "${response}" >&2
        exit 1
    fi
}

log_in() {

    if [[ ${force} -eq 1 ]]; then
        echo "Kicking other clients offline..."
        do_log_out
    fi

    echo "Logging in..."
    local response
    # You may pass `-H "Expect:"` to disable curl from adding it.
    response=$(curl "https://net.zju.edu.cn/cgi-bin/srun_portal" -H "Content-Type: application/x-www-form-urlencoded" -d "action=login&username=${username}&password=${password}&ac_id=3&type=1&is_ldap=1&local_auth=1" -s)
    if [[ "${response}" = *"help.html"* || "${response}" = *"login_ok"* ]]; then
        echo "Login successful"
    else
        echo "${response}" >&2
        exit 1
    fi
}

log_out() {
    echo "Logging out..."
    do_log_out
    echo "Logout successful"
}

main() {
    parse_args "$@"
    if [[ ${log_out} -eq 0 ]]; then
        log_in
    else
        log_out
    fi
}

main "$@"
