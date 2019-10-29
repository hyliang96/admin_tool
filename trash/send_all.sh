#!/bin/bash

# ---------------------------------------
# 加载配置文件
# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
. $here/hosts.sh

# ---------------------------------------
# 服务器组名
server_set=$1; shift

# 检查server_set是否有效
valid_server=false
for i in ${server_sets[@]}; do
    if [ "$i" = "$server_set" ]; then
        valid_server=true
        break
    fi
done
if [ "$valid_server" = false ]; then
    echo 'invalid server_set name' >&2
    return
fi

#  服务器列表生成
eval "servers=(\${$server_set[@]})"

# ---------------------------------------
# 参数解析
# 参数预处理
TEMP=$(getopt \
    -o      n \
    --long  no-prompt \
    -n      '参数解析错误' \
    -- "$@")
# 写法
    #   -o     短参数 不需要分隔符
    #   --long 长参数 用','分隔
    #   ``无选项  `:`必有选项  `::` 可由选项
if [ $? != 0 ] ; then echo "格式化的参数解析错误，正在退出" >&2 ; exit 1 ; fi
eval set -- "$TEMP" # 将复制给 $1, $2, ...

# 初始化参数
no_prompt=false

# 处理参数
while true ; do case "$1" in
    # 无选项
    -n|--no-prompt)  no_prompt=true ; shift ;;
    # '--'后是 余参数
    --) shift ; break ;;
    # 处理参数的代码错误
    *) echo "参数处理错误" ; exit 1 ;;
esac ; done


# ---------------------------------------
# 临时文件夹
dir=~/.cache/all
mkdir -p $dir
if [ "$(ls $dir)" != "" ]; then
    rm $dir/* -rf
fi


if [ "`uname -a | grep -E 'gpu[0-9] |gpu1[0-3] |cluster[1-4] '`" != "" ]; then
# 在gpu1-13，cluster1-4
    ssh_config=$here/config_JUN1
else
# 在gpu14-24
    ssh_config=$here/config_JUN2
fi

# 并行遍历个服务器
for server in ${servers[@]}; do
{
    # echo "ssh $server"
    if ! [ "$no_prompt" = true ]; then
        echo "====== $server ======" >> $dir/$server.feedback
    fi
    # ssh -F $ssh_config $server "$cmds" >> $dir/$server.feedback 2>&1
    echo "rsync -aHhzP -e \"ssh -F $ssh_config\" $@ $server:. "
    command rsync -aHhzP -e "ssh -F $ssh_config" $@ $server:. >> $dir/$server.rsync 2>&1
    # ssh -F $ssh_config -o "StrictHostKeyChecking no" $server "$cmds" >> $dir/$server.feedback 2>&1
} &
done
wait

# 输出ssh返回的结果
ls $dir/*.rsync | sort --version-sort | xargs -I {} cat {}
# 删除临时文件夹
rm $dir -rf

unset here
