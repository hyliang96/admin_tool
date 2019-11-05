#!/bin/bash

# ---------------------------------------
# 加载配置文件
# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
. $here/hosts.sh
. $here/utils.sh
. $here/xwatch/xwatch.sh

argparse()
{
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
}



cmd_for_server()
{
    local server="$1"
    local cmd_name="$2"

    if [ "$checkuid" = true ] || [ "$checkgid" = true ]; then
        local id_cmd='echo '
        if [ "$checkuid" = true ]; then
            id_cmd+="\$(id '$uid' 2>&1 | grep -v 'no such user')  '       '"
        fi
        if [ "$checkgid" = true ]; then
            id_cmd+="\$(getent group '$gid')"
        fi
        local local_cmds=(command ssh -o 'StrictHostKeyChecking=no' "$server" "${id_cmd}")
    elif [ "$send" = 'true' ]; then
        local local_cmds=(command rsync -aHhzP -e "ssh -o 'StrictHostKeyChecking=no'" "${files[@]}" "$server:$server_path")
    else
        local local_cmds=(command ssh -o 'StrictHostKeyChecking=no' "$server" "$cmds")
    fi
    # declare -p local_cmds
    # echo "${cmd_name}"'=("${local_cmds[@]}")'
    eval "${cmd_name}"'=("${local_cmds[@]}")'
}



argparse "$@"

xwatch_args=()
for ((i=1; i<=${#servers}; i++)); do
    cmd=()
    cmd_for_server "${servers[$i]}" cmd
    xwatch_args+=("${cmd[@]}" "${servers[$i]}::")
done

if [ "$no_prompt" = false ]; then
    xwatch_args=('--show_tag' "${xwatch_args[@]}")
fi
if [ "$checkuid" = true ] || [ "$checkgid" = true ]; then
    xwatch_args=('--compact_summary' '--no_gap' "${xwatch_args[@]}")
fi

xwatch --no_command  "${xwatch_args[@]}"

if [ "$checkuid" = true ] || [ "$checkgid" = true ]; then
    echo "The uid/gid is available ONLY IF no server returns information about the uid/gid"
fi
