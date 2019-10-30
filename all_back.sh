#!/bin/bash

# ---------------------------------------
# 加载配置文件
# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
. $here/hosts.sh
. $here/utils.sh


# ---------------------------------------
# 参数解析
# 参数预处理
TEMP=$(getopt \
    -o      nsu:g: \
    --long  no-prompt,send,uid:,gid: \
    -n      '参数解析错误' \
    -- "$@")
# 写法
    #   -o     短参数 不需要分隔符
    #   --long 长参数 用','分隔
    #   ``无选项  `:`必有选项  `::` 可有选项
if [ $? != 0 ] ; then echo "格式化的参数解析错误，正在退出" >&2 ; exit 1 ; fi
eval set -- "$TEMP" # 将复制给 $1, $2, ...

# 初始化参数
no_prompt=false
send=false
checkuid=false
checkgid=false

# 处理参数
while true ; do case "$1" in
    # 无选项
    -n|--no-prompt)  no_prompt=true  ; shift ;;
    -s|--send)       send=true; shift ;;
    # 必有选项
    -u|--uid)        no_prompt=true; checkuid=true; uid=$2; shift 2 ;;
    -g|--gid)        no_prompt=true; checkgid=true; gid=$2; shift 2;;
    # '--'后是 余参数
    --) shift ; break ;;
    # 处理参数的代码错误
    *) echo "参数处理错误" ; exit 1 ;;
esac ; done

# ---------------------------------------
# 服务器组名
if [ "$checkuid" = true ]; then
    server_set=$1; shift
elif [ "$send" = true ]; then
    server_set_path="${@:$#}"
    set -- "${@:1:$(($# - 1))}"
    files=("${@}")
    server_set="${server_set_path%%:*}"  # 第一个':'左侧
    server_path="${server_set_path#*:}" # 第一个':'右侧
else
    server_set=$1; shift
fi

servers=()
parse_server_set "$server_set" servers

# ---------------------------------------
# 命令生成
if [ "$checkuid" = true ] || [ "$checkgid" = true ]; then
    :
elif [ "$send" = true ]; then
    :
else
    cmds=''
    for i in "$@"; do
        if [ "$no_prompt" = true ]; then
            cmds="${cmds} $i; echo;"
        else
            i_print="${i//\\/\\\\}"
            i_print="${i_print//\`/\\\`}"
            i_print="${i_print//\$/\\\$}"
            i_print="${i_print//\"/\\\"}"
            cmds="${cmds} echo -E \"# $i_print\"; $i; echo;"
        fi
    done
    # echo -E "cmds: $cmds"
fi

# ---------------------------------------
# 临时文件夹
runid="$(hostname)-$(date "+%Y-%m-%d_%H-%M-%S")"
dir=~/.cache/all/$runid
mkdir -p $dir
if [ "$(ls -a $dir)" != "" ]; then
    rm $dir  -rf
    mkdir -p $dir
fi


if [ "$host_group" = 'JUN1' ]; then
# 在gpu1-13，cluster1-4
    ssh_config=$here/config_JUN1
elif [ "$host_group" = 'JUN2' ]; then
# 在gpu14-24
    ssh_config=$here/config_JUN2
fi


# # ---------------------------------------
# # 检查每台服务器可连接
# touch $dir/reachable_servers
# for server in ${servers[@]}; do
# {
#     temp="$(ssh -o ConnectTimeout=1 $server 'echo reachable_server' 2>&1)"
#     if [[ "$temp" =~ 'reachable_server' ]]; then
#         echo "$server" >> $dir/reachable_servers
#     else
#         echo "$server Can Not Connet: $temp" >&2
#     fi
# } &
# done
# wait

# IFS_old=$IFS
# IFS=$'\r\n'
# servers=($(<$dir/reachable_servers))
# IFS=$IFS_old




init_dir()
{
    # 初始化：servers和unfinished_output
    touch $dir/servers
    for server in ${servers[@]}; do
        echo "$server" >> $dir/servers
    done
    unset -v server
    touch $dir/finished
    echo "${servers[@]}" >> $dir/unfinished_output
    make_output
    update_output_file


    if ! [  -f "$dir/servers" ]; then
        echo "no $dir/servers"
        exit 1
    fi
    if ! [  -f "$dir/finished" ]; then
        echo "no $dir/finished"
        exit 1
    fi
    if ! [  -f "$dir/unfinished_output" ]; then
        echo "no $dir/unfinished_output"
        exit 1
    fi
    if ! [  -f "$dir/output_file" ]; then
        echo "no $dir/output_file"
        exit 1
    fi

    if [ "$checkuid" = true ]; then
        echo uid $uid available > $dir/info_uid
    fi
    if [ "$checkgid" = true ]; then
        echo gid $gid available > $dir/info_gid
    fi
}


# watch -n 1 -t "echo 'hosts in wait (ctrl+C to stop waiting):' && cat $dir/unfinished_output && echo && ls $dir/*.feedback 2> /dev/null | sort --version-sort | xargs -I {} cat {}" &


# 退出进程
function exit_func()
{
    # 杀死所有子进程
    pkill -P $$
    # 输出总结信息
    [ "$checkuid" = true ] && cat $dir/info_uid
    [ "$checkgid" = true ] && cat $dir/info_gid
    # 输出所有ssh返回的结果
    local files=($dir/*.feedback) 2> /dev/null
    [ -f "${files[1]}" ] && { ls $dir/*.feedback | sort --version-sort | xargs -I {} cat {}; }
    # 报告未完成的服务器的名单
    echo -n 'unfinished servers:' && cat $dir/unfinished_output
    # 删除临时文件夹
    if [ -d "$dir" ] && rm $dir -rf
    unset here
    # exit 1
}

function exit_script() {
    exit_func
    # 退出程序
    exit 1
}

function ctrl_c() {
    exit_func
    # 杀死本进程及其子进程
    kill 0
}

trap ctrl_c SIGINT
# trap ctrl_c TERM
# trap "exit" INT TERM ERR
# trap "exit" TERM ERR
# trap "kill 0" EXIT

deal_server() {
    # connect host
    if ! [ "$no_prompt" = true ]; then
        echo "====== $server ======" >> $dir/$server.feedback
    fi
    if [ "$checkuid" = true ] || [ "$checkgid" = true ]; then
        feedback=""
        if [ "$checkuid" = true ]; then
            result="$(ssh $server id $uid 2>&1)"
            if ! [[ "$result" =~ 'no such user' ]]; then
                echo uid $uid not available > $dir/info_uid
                feedback="$feedback     $result"
            fi
        fi
        if [ "$checkgid" = true ]; then
            result="$(ssh $server getent group $gid)"
            if ! [ "$result" = '' ]; then
                echo gid $gid not available > $dir/info_gid
            feedback="$feedback     group $result"
            fi
        fi
        if ! [ "$feedback" = '' ]; then
            feedback="$server:$feedback"
            echo $feedback >> $dir/$server.feedback 2>&1
        fi
    elif [ "$send" = 'true' ]; then
        # echo "rsync -aHhzP -e \"ssh -F $ssh_config\" $@ $server:$server_path "
        # command rsync -aHhzP -e "ssh -F $ssh_config" $@ \
            # $server:$server_path >> $dir/$server.feedback 2>&1
        echo "rsync -aHhzP -e \"ssh -o 'StrictHostKeyChecking no'\"  ${files[@]} $server:$server_path " >> $dir/$server.feedback 2>&1
        command rsync -aHhzP -e "ssh -o 'StrictHostKeyChecking no'" ${files[@]} $server:$server_path >> $dir/$server.feedback 2>&1
    # command表示系统原版rsync命令
    else
        ssh -o 'StrictHostKeyChecking no' $server "$cmds" >> $dir/$server.feedback 2>&1
        # ssh -F $ssh_config $server "$cmds" >> $dir/$server.feedback 2>&1
        # ssh -F $ssh_config -o 'StrictHostKeyChecking no' $server "$cmds" >> $dir/$server.feedback 2>&1
    fi
    #-- collect unfinished servers --
    echo "$server" >> $dir/finished
    # 计算差集 servers - finished
    unfinished="`sort --version-sort $dir/servers $dir/finished | uniq -u`"
    # unfinished中换行符换为空格
    unfinished="${unfinished//
/ }"
    # unfinished_output 文件仅一行，为未返回结果的服务器名，已排序
    echo $unfinished > $dir/unfinished_output
    # 制作文件
    make_output
}



# 创建 output文件
make_output()
{
    local timestamp=$(date +%s%N)
    local hot_file_name=${dir}/hot_output_file-time${timestamp}
    local file_name=${dir}/output_file-time${timestamp}
    {
        echo 'hosts in wait (ctr+C to stop waiting):'
        cat $dir/unfinished_output
        echo
        # ls $dir/*.feedback 2> /dev/null | sort --version-sort | xargs -I {} cat {}
        local OLD_IFS="$IFS"
        IFS=$'\n'
        local i=
        for i in $(ls -1 $dir/*.feedback 2> /dev/null | sort --version-sort); do
            cat $i
        done
        IFS="$OLD_IFS"
    } 2> /dev/null > ${hot_file_name}
    mv ${hot_file_name} ${file_name}
}




update_output_file()
{
    # if ls $dir/output_file-time* > /dev/null 2>&1; then
    local latest_file="$(ls -1 $dir/output_file-time* 2>/dev/null | sort --version-sort --reverse | head -n 1)"
    if [ "$latest_file" != '' ]; then
        ln -sf ${latest_file} ${dir}/output_file
    fi
    # fi
}



# 更新输出文件 和 退出 的监听
update_exit_listen()
{
    {
        # listen for update
        while true; do
            if [ -f "${dir}/quitvim" ]; then break; fi
            update_output_file
            if [ -f "${dir}/quitvim" ]; then break; fi

            # if finished, add finished flag into output file
            if [ "`sort --version-sort $dir/servers $dir/finished | uniq -u`" = '' ]; then
                update_output_file
                sed -i '1s/^/finished\n/' ${dir}/output_file
                echo 'finished' >> ${dir}/output_file
                break
            fi
            # 不写sleep 1,尽可能早些退出
            if [ -f "${dir}/quitvim" ]; then break; fi
            sleep 0.5
            if [ -f "${dir}/quitvim" ]; then break; fi
            sleep 0.5
        done

        # listen for exit
        while true; do
            # 不写sleep 1,尽可能早些退出
            if [ -f "${dir}/quitvim" ]; then exit_script; fi
            sleep 0.5
            if [ -f "${dir}/quitvim" ]; then exit_script; fi
            sleep 0.5
        done
    } &
}




# 主循环
main_loop()
{
    {
        local server
        for server in ${servers[@]}; do
            ( (
                deal_server $server
            ) & ) > /dev/null 2>&1
        done
        wait
    } &
}

start_monitor()
{
    monitor_file "${dir}/output_file"
}


init_dir
update_exit_listen
main_loop
start_monitor
wait
exit_script

