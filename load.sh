#!/usr/bin/env bash


# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
here="`echo $here | sed 's/^\/mfs\/\([^\/]\+\)/\/home\/\1\/mfs/'`"
admin_tool_path="${here}"


alias _all="zsh $here/all.sh"
all()
{
    _all "$@"
}

alltest()
{
    if [ $# -eq 0 ]; then
        local server_set='a'
    else
        local server_set="$1"
    fi
    all "$server_set" 'echo "hello world"'
}

alias _send="zsh $here/all.sh --send"
send()
{
    _send "$@"
}

alluid()
{
    local server_set=
    if [ $# -eq 1 ]; then
        server_set="a"
    else
        server_set="$1"
        shift
    fi
    local uid="$1"
    all "$server_set" --uid $uid --gid $uid
}

allgid()
{
    local server_set=
    if [ $# -eq 1 ]; then
        server_set="a"
    else
        server_set="$1"
        shift
    fi
    local gid="$1"
    all "$server_set" --gid $gid
}


if [[ "`type allgpu 2>&1`" =~ 'alias' ]]; then
    unalias allgpu
fi
allgpu()
{
    local server_set=
    if [ $# -eq 0 ]; then
        server_set=g
    else
        server_set="$1"
    fi
    all "$server_set" --no-prompt 'gpustat'
}

# use sudo to do something with this package
admin()
{
    # echo "$@"
    # echo "$*"
    # local commands=''
    # for i in "$@"; do
        # # echo -E "$i"
        # if [[ "$i" =~ ' ' ]]; then
            # local i="${i//\"/\\\"}"
            # local i="${i//\$/\\\$}"
            # local commands="$commands \"$i\""
        # else
            # local commands="$commands $i"
        # fi
    # done
    # echo commands: $commands
    # commands="${commands//\`/\\\`}"
    # echo commands: $commands

    if [ "$1" = '-h' ] || [ "$1" = '--help' ]; then
        echo "\`admin\` to run commands with admin_tool package"
        echo "Usage:"
        echo "admin 'command1' [ 'command2' ... ]"
        echo "admin \"command1\" [ \"command2\" ... ]"
        return
    fi

    local cmds=''
    for i in "$@"; do
        local cmds="$cmds $i;"
    done
    echo "cmds: $cmds"
    sudo su -c ". $admin_tool_path/load.sh && $cmds"
}


# 按大小升序列出当前目录下所有文件与文件夹, 单位为G的
alias _slG="zsh $here/slG.sh"
slG()
{
    _slG "$@"
}
alias sl_home="sudo zsh $admin_tool_path/slG.sh /home"

# slG()
# {
    # local tmp_log=$(mktemp /tmp/tmp.XXXXXXXXXX)
    # echo $tmp_log
    # local exit_func() {
        # pkill -P $$
        # rm $tmp_log
    # }
    # trap exit_func SIGINT

    # du -axhd1  --block-size=1G $@ >> $tmp_log &

    # watch -n 1 -t "sort -n $tmp_log"

    # # wait

    # # exit_func

# }

. $here/user_manage.sh

. $here/mfs_set.sh

. $here/software.sh


unset here
