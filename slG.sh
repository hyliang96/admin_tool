#!/usr/bin/env bash

admin_tool_path=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
admin_tool_path="`echo $admin_tool_path | sed 's/^\/mfs\/\([^\/]\+\)/\/home\/\1\/mfs/'`"
. ${admin_tool_path}/xwatch/xwatch.sh

tmp_root=$(mktemp -d -t slG.XXXXXXX)
tmp_log=${tmp_root}/log
tmp_log_sort=${tmp_root}/tmp_log_sort
quitvim=${tmp_root}/quitvim
tmp_finish=${tmp_root}/tmp_finish;        touch $tmp_finish



exit_func() {
    # 杀死所有子进程
    pkill -P $$
    # cat $tmp_log_sort
    sort -n $tmp_log
    # if [ "`cat $tmp_finish`" = 'finished' ]; then echo finished; else echo unfinished; fi
    if [ "`cat $tmp_finish`" = 'finished' ]; then echo finished ; else echo unfinished; fi
    [ -d $tmp_root ] && rm  -rf $tmp_root
}

exit_script() {
    exit_func
    # 退出程序
    exit 1
}

ctrl_c() {
    exit_func
    # 杀死本进程及其子进程
    kill 0
}


trap ctrl_c SIGINT
# trap "exit" INT TERM ERR
# trap "kill 0" EXIT
# trap 'kill background' EXIT



pathset=()
for upper_path in "$@"; do
    upper_file_sys="$(df $upper_path | tail -n1 | awk '{print $1}')"
    OLD_IFS="$IFS"
    IFS=$'\n'
    for i in $(ls -a1 $upper_path 2> /dev/null | grep -vE '^(.|..)[/]*$'); do
        suber_path=$upper_path/$i
        file_sys="$(df $suber_path | tail -n1 | awk '{print $1}')"
        if [ "$file_sys" = "$upper_file_sys" ]; then
            pathset+=("$suber_path")
        fi
    done
    IFS="$OLD_IFS"
done




{
    for i in "${pathset[@]}"; do
    {
        du  -axhd0  --block-size=1G $i >> $tmp_log 2>&1
    } &
    done
    wait
    # du -axhd1  --block-size=1G $@ >> $tmp_log
    echo finished >> $tmp_finish
}  &


update_log_sort() {
    {
        if [ "`cat $tmp_finish`" = 'finished' ]; then
            echo 'finished'
        else
            echo $'Waiting ... ctrl+c to stop\n'
        fi
        sort -n -r $tmp_log
    } > $tmp_log_sort
}

{
    while true; do
        update_log_sort
        if  [ -f $quitvim ]; then  break; fi
        for i in {1..10}; do
            sleep 0.1
            if  [ -f $quitvim ]; then  break; fi
        done
    done

    while true; do
        if  [ -f $quitvim ]; then  exit_script; fi
        sleep 0.1
    done
} &

xwatch --file --quitvim "$tmp_log_sort"

wait

exit_script
