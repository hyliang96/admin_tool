#!/usr/bin/env zsh

__mfsquota_all() {
    (
    echo "user\tindices\tsize"

    local i=
    for i in /mfs/*; do
        local quota_i="$(sudo mfsgetquota -h $i)"
        local username="$(echo "${quota_i}" | head -n1|awk -F ':' '{printf $1}'|awk -F '/' '{printf $3}')"
        local index_num="$(echo "${quota_i}" | head -n2 | tail -n1 | awk -F '|' '{printf $2}')"
        local size="$(echo "${quota_i}" | head -n4 | tail -n1 | awk -F '|' '{printf $2}')"
        echo "${username}\t${index_num}\t${size}"
    done
    ) | column -t -s $'\t'
}

__mfsquota_user() {
    if [ $# -ge 1 ]; then
        local i=
        for i in "${@}"; do
            sudo mfsgetquota -h "/mfs/${i}"
            echo
        done
    else
        echo 'usage:'
        echo '    __mfsquota_user <username> [<username> ...]'
    fi
}

cl_mfs() {
    if [ $# -eq 0 ]; then
        echo '/mfs:'
        local result="$(__mfsquota_all)"
        echo "${result}" | head -n 1
        echo "${result}" | tail -n +2 | sort --human-numeric-sort -k 2 -r | head -n 51 # awk  '$2 ~ /Ki/ { print }'
    else
        __mfsquota_user "$@"
    fi
}

sl_mfs() {
    if [ $# -eq 0 ]; then
        echo '/mfs:'
        local result="$(__mfsquota_all)"
        echo "${result}" | head -n 1
        echo "${result}" | tail -n +2  | sort --human-numeric-sort -k 3 -r | head -n 51 # awk  '$3 ~ /GiB/ { print }'
    else
        __mfsquota_user "$@"
    fi
}

alias du_mfs='sl_mfs'

