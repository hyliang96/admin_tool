#!/usr/bin/env zsh


mount_point=$(df /home | awk 'NR!=1' | awk '{print $NF}')
reserved_size=10 # GB

size="$(df -h /home | awk 'NR!=1' | awk '{print $2}')"
hard_total_quota="$(( ${size:0:-1} - $reserved_size ))" # hard quota for all normal users (i.e. quota group)
hard_user_quota="$(( $hard_total_quota * 0.14 ))"       # hard quota for each normal user
soft_user_quota="$(( $hard_user_quota * 0.7 ))"         # soft quota for each normal user

hard_user_quota="${hard_user_quota%.*}"
soft_user_quota="${soft_user_quota%.*}"

echo ${hard_total_quota}G
echo ${soft_user_quota}G ${hard_user_quota}G

# sudo groupadd quota
# sudo setquota -g quota 0 ${hard_total_quota}G 0 0 $mount_point
# sudo quota -vsg  quota

for user in $(awk -F: '{ if($3>=500) print $1}' /etc/passwd); do
    # sudo usermod -aG quota $user
    sudo setquota -u $user ${soft_user_quota}G ${hard_user_quota}G 0 0 $mount_point
    sudo quota -vs $user
    # break
done

sudo repquota -s $mount_point

