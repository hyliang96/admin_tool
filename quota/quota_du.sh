#!/usr/bin/env zsh

quota_du() {
  mount_point=$(df /home | awk 'NR!=1' | awk '{print $NF}')
  quota_report="$(sudo repquota -s $mount_point)"
  { echo "quota of used disk size on $mount_point" && echo $quota_report | awk 'NR<=5' && echo $quota_report | awk 'NR>5' | sort -h -k 3 -r ; } | less
}
