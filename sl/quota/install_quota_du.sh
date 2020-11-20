#!/usr/bin/env zsh

# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)

. $here/quota_du.sh

install_quota_du() {
    echo "\n> sudo apt update"
    sudo apt update

    echo "\n> sudo apt install -y"
    sudo apt install quota -y

    echo "\n> sudo quota --version"
    result="$(sudo quota --version)"
    echo ${result}
    ! [[ "$result" =~ 'Quota utilities version' ]] && return

    echo "\n> (find /lib/modules/`uname -r` -type f -name '*quota_v*.ko*'"
    result="$(find /lib/modules/`uname -r` -type f -name '*quota_v*.ko*')"
    echo "${result}"
    [  "${result}" = '' ] &&     return

    mount_point=$(df /home | awk 'NR!=1' | awk '{print $NF}')
    echo "\nquota disk: $mount_point"

    echo "\n> edit /etc/fstab"
    awk '{if ($2=="'"$mount_point"'" &&  $4!~"usrquota" && $4!~"grpquota"  ) $4=$4",usrquota,grpquota"}1' /etc/fstab | sudo tee /etc/fstab

    sudo mount -o remount ${mount_point}
    echo "\n> sudo cat /proc/mounts | grep \" $mount_point \""
        result=$(sudo cat /proc/mounts | grep " $mount_point ")
        echo ${result}
    ! ( [[  "${result}" =~ 'usrquota' ]] &&  [[  "${result}" =~ 'grpquota' ]] ) &&    return

    echo "\n> sudo quotacheck -ugm $mount_point"
    sudo quotacheck -ugm $mount_point

    echo "\n> ls $mount_point | grep aquota"
    ls $mount_point | grep aquota

    echo "\n> sudo quotaon -v $mount_point"
    result="$(sudo quotaon -v $mount_point)"
    echo "$result"
    ! ( [[ "$result" =~ 'group quotas turned on' ]] && [[ "$result" =~ 'user quotas turned on' ]] ) && return

    echo "\n> quota_du"
    quota_du
}

install_quota_du

# release this variable in the end of file
unset -v here
