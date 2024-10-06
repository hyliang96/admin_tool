#!/usr/bin/env zsh

quota_du() {
    if [ $# -eq 0 ]; then
        local target_dir="/home"
    else
        local target_dir="$1"
    fi
    local mount_point=$(df "${target_dir}" | awk 'NR!=1' | awk '{print $NF}')
    local quota_report="$(sudo repquota -vs $mount_point)"

    local meta_info="${quota_report%%                        Space limits                File limits*}"
    local no_meta_info="${quota_report#*                        Space limits                File limits}"

    local table=$(
        echo -n "                        Space limits                File limits"
        echo -n "${no_meta_info%%Statistics:*}"
    )
    local table_head="${table%%----------------------------------------------------------------------*}"
    local table_line='----------------------------------------------------------------------'
    local table_body="${table#*----------------------------------------------------------------------}"

    local statistics="Statistics:${no_meta_info#*Statistics:}"


    echo "quota of used disk size on $(hostname):$mount_point"
    echo
    echo -n $meta_info
    {
        echo -n $table_head
        echo  $table_line
        echo -n $table_body | sort -rh -k3

    } | sed -E 's/Space limits/|              Space limits/; s/^User      /User      |/; s/^----------/----------|/ ;s/^([^ ]+) +(.+)/\1|\2/' | \
        column -te -s'|' | \
        sed -E '/^----------/s/ /-/g'

    echo -n $statistics
}

alias sl_quota='quota_du'
