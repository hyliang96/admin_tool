#!/usr/bin/env bash

# ---------------------------------------
# 加载配置文件
# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
. $here/hosts.sh


rmlink()
{
    for i in "$@"; do
        if [ -L "$i" ]; then
            rm "$i"
        fi
    done
}
lkdir()
{
    if [ -d "$1" ]; then
        ln -sfT "$1" "$2"
    fi
}
link_to_backup()
{
    rmlink /home/${USER}/ENV/{CONF,shareENV,serverENV,junENV}

    lkdir /home/${USER}/ENV/ENV_backup/CONF      /home/${USER}/ENV/CONF
    lkdir /home/${USER}/ENV/ENV_backup/shareENV  /home/${USER}/ENV/shareENV
    lkdir /home/${USER}/ENV/ENV_backup/serverENV /home/${USER}/ENV/serverENV
    lkdir /home/${USER}/ENV/ENV_backup/junENV    /home/${USER}/ENV/junENV
}
link_to_mfs()
{
    # rmlink /home/${USER}/ENV/{CONF,shareENV,serverENV,junENV}

    lkdir /home/${USER}/mfs/server_conf/ENV/CONF      /home/${USER}/ENV/CONF
    lkdir /home/${USER}/mfs/server_conf/ENV/shareENV  /home/${USER}/ENV/shareENV
    lkdir /home/${USER}/mfs/server_conf/ENV/serverENV /home/${USER}/ENV/serverENV
    lkdir /home/${USER}/mfs/server_conf/ENV/junENV    /home/${USER}/ENV/junENV
}
usshmfs() # `usshmfs`：卸载ssh挂载的mfs
{
    # 本地shareENV、serverENV、CONF链接改指向shareENV_backup、serverENV_backup、CONF_backup
    link_to_backup
    # [ -L /home/${USER}/ENV/CONF ] && rm /home/${USER}/ENV/CONF
    # [ -L /home/${USER}/ENV/shareENV ] && rm /home/${USER}/ENV/shareENV
    # [ -L /home/${USER}/ENV/serverENV ] && rm /home/${USER}/ENV/serverENV
    # [ -L /home/${USER}/ENV/junENV ] && rm /home/${USER}/ENV/junENV


    # if [ -d /home/${USER}/ENV/CONF_backup ]; then
        # ln -s /home/${USER}/ENV/CONF_backup /home/${USER}/ENV/CONF
    # fi
    # if [ -d /home/${USER}/ENV/shareENV_backup ]; then
        # ln -s /home/${USER}/ENV/shareENV_backup /home/${USER}/ENV/shareENV
    # fi
    # if [ -d /home/${USER}/ENV/serverENV_backup ]; then
        # ln -s /home/${USER}/ENV/serverENV_backup /home/${USER}/ENV/serverENV
    # fi
    # if [ -d /home/${USER}/ENV/junENV_backup ]; then
        # ln -s /home/${USER}/ENV/junENV_backup /home/${USER}/ENV/junENV
    # fi

    # 因为HOME=/home/${USER}/ENV/shareENV/CONF

    # 如果这个目录不被占用，则卸挂载，无需sudo
    # fusermount -u /home/${USER}/mfs

    # 即使被这个目录占用也强行卸挂载，需要sudo
    sudo umount -l /home/${USER}/mfs
}



sshmfs_()
{
    # 本地shareENV、CONF链接改指向shareENV_backup、CONF_back


    if [ $# -eq 0 ]; then
        local _mfs_source="$mfs_source"
    else
        local _mfs_source="$1"
    fi


    # 挂载${hostname}上的mfs
    if [ -d /home/${USER}/mfs ]; then
        echo command sshfs $_mfs_source:/mfs/haoyu /home/${USER}/mfs -o allow_other,default_permissions,reconnect
        command sshfs $_mfs_source:/mfs/haoyu /home/${USER}/mfs -o allow_other,default_permissions,reconnect
        echo $(ls /home/$USER/mfs/)
        # 由于已经配置好了`/etc/ssh/ssh_config`，故不再需要`-F $local_ssh_config`
        # command sshfs -F $local_ssh_config $_mfs_source:/mfs/haoyu /home/${USER}/mfs -o allow_other,default_permissions &&  ls /home/$USER/mfs/
    fi

    # # 创建本地linkENV链接，并将本地shareENV链接改指向mfs下的shareENV
    link_to_mfs
    # if [ -d /home/haoyu/mfs/server_conf/ENV/CONF ]; then
        # ln -sf /home/haoyu/mfs/server_conf/ENV/CONF /home/${USER}/ENV/CONF
    # fi

    # if [ -d /home/haoyu/mfs/server_conf/ENV/shareENV ]; then
        # ln -sf /home/haoyu/mfs/server_conf/ENV/shareENV /home/${USER}/ENV/shareENV
    # fi

    # if [ -d /home/haoyu/mfs/server_conf/ENV/serverENV ]; then
        # ln -sf /home/haoyu/mfs/server_conf/ENV/serverENV /home/${USER}/ENV/serverENV
    # fi

    # if [ -d /home/haoyu/mfs/server_conf/ENV/junENV ]; then
        # ln -sf /home/haoyu/mfs/server_conf/ENV/junENV /home/${USER}/ENV/junENV
    # fi
}


# 用sshfs挂载mfs，如在gpu16上，即将g3上的mfs挂载到g16
# `sshfs [服务器](仅一个服务器)`
# 如 `sshmfs g3`
# 如 `sshmfs -p 4707 haoyu@ml.cs.tsinghua.edu.cn`
sshmfs()
{
    # 卸挂载
    # 如果先不把所有指向挂载的mfs下的链接删掉，会挂载进程锁死
    usshmfs

    sshmfs_ $@
}

# 查看所有占用/home/$USER/mfs 的进程
# 若显示"umount(<mount_path>): Resource busy -- try 'diskutil unmount'"
# 则执行此命令，观察哪些进程占用了挂载目录
alias jchmfs='lsof /home/$USER/mfs/'



mfsstart()
{
    if [ "$mfs_source" = '' ]; then
        sudo mfsmount /mfs -H mfsmaster &&  mfsmetalogger start && ls /home/$USER/mfs/
    else
        sudo sshfs  $mfs_source:/mfs /mfs -o allow_other,default_permissions
    fi
    echo 'ls /mfs | head -n 10'
    echo $(ls /mfs | head -n 10)
}

# 开启原生的mfs
alias __allmfsstart="all J1 '. $here/load.sh; mfsstart'"
_allmfsstart()
{
    __allmfsstart
}
alias allmfsstart="sudo su -c '. $here/load.sh; _allmfsstart'"
# 注意，不可把 _allsshmfs 写成一个 alias，必需写成function
# 这是因为 su -c 'xxxx' 是非交互式登录，故未经专门设置则不支持alias，只支持function


allusshmfs()
{
    if [ $# -eq 0 ]; then
        local server_set='J23'
    else
        local server_set="$1"
    fi
    sudo su -c ". $admin_tool_path/load.sh && all '$server_set' 'su -l $USER -c \"link_to_backup\" && umount -l /home/haoyu/mfs'"
}

# 重新用sshfs挂载mfs
_allsshmfs()
{
    if [ $# -eq 0 ]; then
        local server_set='J23'
    else
        local server_set="$1"
    fi
    if [ $# -eq 2 ]; then
        local mfs_host="$2"
    else
        local mfs_host=""
    fi
    all --timeout 10 "$server_set" "sshmfs_ $mfs_host "
    # all J23 'umount -l /home/haoyu/mfs; su -l haoyu -c \"command sshfs \$_mfs_source:/mfs/haoyu /home/\${USER}/mfs -o allow_other,default_permissions,reconnect &&  ls /home/\$USER/mfs/\"'
}

# 重新用sshfs挂载mfs
# allsshmfs 机器编组 [一台sshmfs源服务器 缺省则为每台服务器对口的sshmfs源服务器]
# 机器编组：可以只写一台服务器, 可以写多台 形如'g{2..4} g8 g10'
allsshmfs()
{
    local args=''
    for i in "$@"; do
        args+=" '$i'"
    done
    echo '===================== usshmfs ===================='
    eval "allusshmfs $args"
    echo '===================== sshmfs ====================='
    eval "_allsshmfs $args"
    # echo "`eval echo $here`"
    # if [ $# -eq 0 ]; thenSSSSS
        # sudo su -c ". $admin_tool_path/load.sh; _allsshmfs"
    # elif [ $# -eq 1 ]; then
        # sudo su -c ". $admin_tool_path/load.sh; _allsshmfs '$1'"
    # else
        # sudo su -c ". $admin_tool_path/load.sh; _allsshmfs '$1' '$2'"
    # fi
}

# 将所有mfs开启
alias allmfs='allmfsstart; allsshmfs'

all_unlock_mfsback()
{
    if [ $# -eq 0 ]; then
        local server_set="a"
    else
        local server_set="$1"
    fi
   all "$server_set"  'rm /home/haoyu/ENV/localENV/log/backup_config_thru_mfs/.backup.lock'
}


all_ssh_preenv_pull()
{
    if [ $# -eq 0 ]; then
        local server_set="a"
    else
        local server_set="$1"
    fi
    sudo su -c ". $admin_tool_path/load.sh && all '$server_set'  \
        'su -l $USER -c \"ssh_pull; preenv_pull\"'"
}

# 当/home/$USER/{.preenv,.ssh/}坏损, 在cpu1上执行次命令, 将cpu1上的.preenv,.ssh/ 发送到各个服务器
send_ssh_preenv()
{
    if [ $# -eq 0 ]; then
        local server_set="a"
    else
        local server_set="$1"
    fi
    sudo su -c ". $admin_tool_path/load.sh && send --delete $HOME/.shell_config/.preenv $junENV/key/.ssh '$server_set:/home/$USER'"
}

# unset here
