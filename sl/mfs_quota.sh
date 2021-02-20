#!/usr/bin/env zsh

__mfsquota() {
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

quota_mfs() {
    if [ $# -ge 1 ]; then
        local i=
        for i in "${@}"; do
            sudo mfsgetquota -h "/mfs/${i}"
            echo
        done
    else
        echo 'usage:'
        echo '    quota_mfs <username> [<username> ...]'
    fi
}

cl_mfs() {
    echo '/mfs:'
    local result="$(__mfsquota)"
    echo "${result}" | head -n 1
    echo "${result}" | tail -n +2 | sort --human-numeric-sort -k 2 -r | head -n 51 # awk  '$2 ~ /Ki/ { print }'
}

sl_mfs() {
    echo '/mfs:'
    local result="$(__mfsquota)"
    echo "${result}" | head -n 1
    echo "${result}" | tail -n +2  | sort --human-numeric-sort -k 3 -r | head -n 51 # awk  '$3 ~ /GiB/ { print }'
}

alias du_mfs='sl_mfs'

