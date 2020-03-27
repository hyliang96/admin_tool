#!/usr/bin/env zsh
# 只可用zsh执行

# 加quota的文件系统为 /home 所在的文件系统
quota_filesys=$(df /home | awk 'NR!=1' | awk '{print $NF}')

if [ "$1" = '--unset' ]; then
    # 取消普通用户(UID大于等于500)的quota
    for user in $(awk -F: '{ if($3>=500) print $1}' /etc/passwd); do
        sudo setquota -u $user 0 0 0 0 $quota_filesys
        sudo quota -vs $user # 显示普通用户的quota
    done
elif [ $# -eq 0 ]; then
    filessys_size="$(df $quota_filesys | awk 'NR!=1' | awk '{print $2}')"

    hard_user_quota="$(( $filessys_size  * 0.15 ))" # hard quota for each normal user
    soft_user_quota="$(( $hard_user_quota * 0.5 ))" # soft quota for each normal user
    # 四舍五入
    hard_user_quota="${hard_user_quota%.*}"
    soft_user_quota="${soft_user_quota%.*}"

    echo 'quota for all ordinary users'
    echo "soft limit = $(numfmt --from=iec-i --to=iec-i --suffix=B ${soft_user_quota}KiB)"
    echo "hard limit = $(numfmt --from=iec-i --to=iec-i --suffix=B ${hard_user_quota}KiB)"


    # 修改 /home/LargeData 的主人为 "LargeData" 用户
    sudo useradd LargeData
    sudo chown -R LargeData:LargeData /home/LargeData
    sudo chmod -R a+r /home/LargeData
    sudo chmod a+x /home/LargeData/*


    # set group quota for group 'quota'
    # sudo groupadd quota
    # sudo setquota -g quota 0 ${hard_total_quota}G 0 0 $quota_filesys
    # sudo quota -vsg  quota

    # 将普通用户(UID大于等于500)设置quota
    for user in $(awk -F: '{ if($3>=500) print $1}' /etc/passwd); do
        sudo setquota -u $user ${soft_user_quota} ${hard_user_quota} 0 0 $quota_filesys
        sudo quota -vs $user # 显示普通用户的quota
    done

    # 显示所有用户的quota
    sudo repquota -s $quota_filesys

else
    echo "zsh set_quota.sh          : set quota for all ordinary users on $quota_filesys"
    echo "zsh set_quota.sh --unset  : unset quota for all ordinary users on $quota_filesys"
fi
