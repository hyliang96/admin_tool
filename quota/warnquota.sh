#!/bin/bash

# 功能
    # 发送quota警告到所有((超过soft limit未达hard limit的))用户的终端
    # 可以用bash或zsh执行, 但无法用sh执行
    
# 设置每5分钟发送一次quota warning到用户的终端
    # 执行 `sudo crontab -e`
    # 然后在文件结尾写入
    # ```
    # SHELL=/bin/bash   # 默认用bash而不是sh执行warnquota.sh
    # PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin   # 加载quota命令
    # */5 * * * * <path-to-warnquota.sh>
    # ```
    # 然后保存, 退出编辑器

quota_dir=$(df /home | awk 'NR!=1' | awk '{print $NF}')
# quota_dir="$(df /home | awk NR!=1 | awk '{print $6}')"

old_IFS=$IFS
IFS=$'\n'

report=($(repquota -sp $quota_dir | grep -E '\+-|\+\+|-\+') )
# report=($(repquota -spg $quota_dir | grep -E '\+-|\+\+|-\+') )

declare -p report

IFS=' '
for item in "${report[@]}"; do
    echo $item
    info=($(echo -E "$item"))
    id=0

    user="${info[@]:${id}:1}"; id=$(($id + 1))
    exceed="${info[@]:${id}:1}"; id=$(($id + 1))
    if [ ${exceed:0:1} = '+' ]; then size_exceed=1; else size_exceed=0; fi
    if [ ${exceed:1:1} = '+' ]; then num_exceed=1;  else num_exceed=0; fi

    size="${info[@]:${id}:1}"; id=$(($id + 1))
    size_soft_limit="${info[@]:${id}:1}"; id=$(($id + 1))
    size_hard_limit="${info[@]:${id}:1}"; id=$(($id + 1))
    size_grace="${info[@]:${id}:1}"; id=$(($id + 1))

    num="${info[@]:${id}:1}"; id=$(($id + 1))
    num_soft_limit="${info[@]:${id}:1}"; id=$(($id + 1))
    num_hard_limit="${info[@]:${id}:1}"; id=$(($id + 1))
    num_grace="${info[@]:${id}:1}"; id=$(($id + 1))

    echo $user $exceed $size_exceed $num_exceed $size $size_soft_limit $size_hard_limit $size_grace $num $num_soft_limit $num_hard_limit $num_grace

    warning=''

    if [ "$size_exceed" = '1' ] || [ "$num_exceed" = '1' ]; then
        warning+=$'\n'"WARNING: quota under '$quota_dir' is exceeded."$'\n'
    fi

    if [ "$size_exceed" = '1' ]; then
        warning+="Your disk quota:
    used = ${size}B
    soft limit = ${size_soft_limit}B
    hard limit = ${size_hard_limit}B"$'\n'
    fi

    if [ "$num_exceed" = '1' ]; then
        warning+="Your file number quota:
    used = ${num}
    soft limit = ${num_soft_limit}
    hard limit = ${num_hard_limit}"$'\n'
    fi

    if [ "$size_exceed" = '1' ] || [ "$num_exceed" = '1' ]; then
        warning+="Please clean up your files under '$quota_dir'."$'\n'
    fi


    ttys=($(who -T | grep $user | awk '{printf $3 " "}'))
    for tty in "${ttys[@]}"; do
        echo "$user $tty"
        echo -E "$warning"
        echo -E "$warning" | write $user $tty
    done
done


IFS=$old_IFS

