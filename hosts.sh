#!/usr/bin/env bash


mfs_source=''

# 检测服务器的类型、所属局域网
host_name="$(hostname | sed 's/img[0-9]\+//g')"
host_id=$(echo $host_name | tr -cd '[0-9]')
# if [  "$(hostname | tr -d '[0-9]')" = 'img' ] &&  [ $host_id -ge 19 ] && [ $host_id -le 21 ]; then
    # # img19-img20 = jungpu25-jungpu27
    # host_type='gpu'
    # host_group='JUN2'   # 在jungpu>=14
    # host_id="`expr $host_id + 6`"
    # mfs_source='jungpu'"`expr $host_id - 18`" # jungpu25-27 -> jungpu7-9

if [ "$(echo $host_name | tr -d '[0-9]')" = 'jungpu' ] ; then
    host_type='gpu'
    if [ $host_id -le 13 ]; then
        host_group='JUN1'   # 在jungpu1-13，juncluster1-4
        if [ $host_id -ge 12 ]; then
            # 在jungpu12-13
            # mfs 用sshfs挂载cpu1-2
            mfs_source='juncluster'"$((  ( $host_id - 11 ) % 11 + 1 ))"
        fi
    else
        host_group='JUN2'   # 在jungpu>=14
        mfs_source='jungpu'"$(( ( $host_id - 13 ) % 11 + 1 ))"
        # jungpuxx 的/mfs用sshfs挂载 jungpu(xx-13) 的 /mfs
    fi
else
    host_type='cpu'
    host_group='JUN1'
fi


# ---------------------- 服务器编组设置------------------
# 顺序编组
# 编组名=(前缀{起始数字..结束数字}后缀)
# 或 编组名=(前缀1{起始数字..结束数字}后缀1  前缀2{起始数字..结束数字}后缀2)
c=(juncluster{1..4})
gJ1=(jungpu{1..11})
gJ2=(jungpu{12..13})
gJ3=(jungpu{14..27})

# 复合编组
# 编组名=( "${子编组1[@]}" "${子编组2[@]}" "${子编组3[@]}" )
g=( "${gJ1[@]}" "${gJ2[@]}" "${gJ3[@]}" )
J1=( "${c[@]}" "${gJ1[@]}" )
J2=( "${gJ2[@]}" )
J3=( "${gJ3[@]}" )
gJ12=( "${gJ1[@]}" "${gJ2[@]}" )
J12=( "${J1[@]}"   "${gJ2[@]}" )
gJ23=( "${gJ2[@]}" "${gJ3[@]}" )
J23=( "${gJ23[@]}" )
a=( "${c[@]}" "${g[@]}" )

# 有效编组：即只有写在此处的编组才会被 `all` 命令使用
server_sets=(gJ1 J1 gJ2 J2 gJ3 J3 gJ12 J12 gJ23 J23 c g a)


# # 用不了的gpu
# INVALID_GPU=()
# export INVALID_GPU
# # 用不了的cpu
# INVALID_CPU=()
# export INVALID_CPU


