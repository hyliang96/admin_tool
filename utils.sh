#!/bin/bash

is_array() {
    local array_name="$1"
    if [[ "$(declare -p $array_name)" =~ 'declare -a ' ]] || \
       [[ "$(declare -p $array_name)" =~ 'typeset -g -a ' ]] || \
       [[ "$(declare -p $array_name)" =~ 'typeset -a ' ]] ; then
        echo true
    else
        echo false
    fi
}


here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
. $here/path.sh
. $here/hosts.sh

# 检查server_set_是否有效
parse_server_set()
{
    # echo '$1:' $1
    # echo 1
    # local server_set_=
    # local server_set_
    # declare -a server_set_
    # unset -a server_set_
    eval "server_set_=($1)"
    # echo 2

    local servers_var="$2"
    eval "$servers_var=()"

    if ! [ "$(is_array server_set_)" = true ]; then
        echo 'invalid server_set_' >&2
        echo "Usage: <server_set_name> '<command>'"
        echo "Usage: 'server1 server2 server3' '<command>'"
        echo "Usage: all 'server1 server2 server{3..5} server{10..13}' '<command>'"
        exit
    fi

    for i in $server_set_; do
        if [[ " ${server_sets[@]} " =~ " $i " ]]; then
            eval "$servers_var=( \${$servers_var[@]} \${$i[@]} )"
        else
            eval "$servers_var=( \${$servers_var[@]} $i )"
        fi
    done

    # valid_server=false
    # for i in ${server_sets[@]}; do
        # if [ "$i" = "$server_set_" ]; then
            # valid_server=true
            # break
        # fi
    # done

    # if [ "$valid_server" = false ]; then
        # #  服务器列表生成
        # eval "$servers_var=($server_set_)"
        # if ! [ "$(is_array $servers_var)" = true ]; then
            # echo 'invalid server_set_' >&2
            # echo "Usage: <server_set_name> '<command>'"
            # echo "Usage: 'server1 server2 server3' '<command>'"
            # echo "Usage: all 'server1 server2 server{3..5} server{10..13}' '<command>'"
            # exit
        # fi
    # else
        # #  服务器列表生成
        # eval "$servers_var=(\${$server_set_[@]})"
    # fi
    unset server_set_
}



alias monitor_file="\vim -u ${admin_tool_path}/monitor_file.vim"
