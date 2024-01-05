#!/usr/bin/env bash


mfs_source=''

# 检测服务器的类型、所属局域网
host_name="$(hostname | sed 's/img[0-9]\+//g')"
host_id="$(echo $host_name | tr -cd '[0-9]')"
host_type="$(echo $host_name | tr -d '[0-9]')"
# if [  "$(hostname | tr -d '[0-9]')" = 'img' ] &&  [ $host_id -ge 19 ] && [ $host_id -le 21 ]; then
    # # img19-img20 = jungpu25-jungpu27
    # host_type='gpu'
    # host_group='JUN2'   # 在jungpu>=14
    # host_id="`expr $host_id + 6`"
    # mfs_source='jungpu'"`expr $host_id - 18`" # jungpu25-27 -> jungpu7-9

# jungpuxx (xx=12-49) 的/mfs 用sshfs挂载 jungpu(xx-11) 的 /mfs
if [ "${host_type}" = 'jungpu' ] ; then
    if [ $host_id -le 11 ]; then       # jungpu1-11
        host_group='J1'
        mfs_source=''
    else
        if [ $host_id -le 13 ]; then   # jungpu12-13
            host_group='J2'
        elif [ $host_id -le 37 ]; then # jungpu14-37
            host_group='J3'
        else                           # jungpu38-49
            host_group='J4'
        fi
        mfs_source='jungpu'"$(( ( $host_id - 11 ) % 11 + 1 ))"
    fi
    [ "${mfs_source}" = 'jungpu2' ] && mfs_source=jungpu3
elif [  "${host_type}" = 'juncluster' ] ; then # juncluster1-5
    host_group='J1'
    mfs_source=''
fi


# ---------------------- 服务器编组设置------------------
# 顺序编组
# 编组名=(前缀{起始数字..结束数字}后缀)
# 或 编组名=(前缀1{起始数字..结束数字}后缀1  前缀2{起始数字..结束数字}后缀2)

# c5: 专供管理员管理集群, 不对其他用户开放

c=(juncluster{1..4})
gJ1=(jungpu1 jungpu{3..11})
gJ2=(jungpu{12..13})
gJ3=(jungpu{14..37})
gJ4=(jungpu{38..49})
gJ5=(jungpu{50..51})

# 复合编组
# 编组名=( "${子编组1[@]}" "${子编组2[@]}" "${子编组3[@]}" )
g=( "${gJ1[@]}" "${gJ3[@]}" "${gJ4[@]}" "${gJ5[@]}" )
J1=( "${c[@]}" "${gJ1[@]}" )
J2=( "${gJ2[@]}" )
J3=( "${gJ3[@]}" )
J4=( "${gJ4[@]}" )
J5=( "${gJ5[@]}" )

a=( "${c[@]}" "${g[@]}" )



# 朱老师课程的学生的课程项目用的机器
kcxm=(jungpu{14..17})

# 本科生或访问学者,只能用4卡机器
bks=(juncluster{2,4} jungpu1 jungpu{3..8} jungpu{10..11} jungpu{14..17} jungpu{21..23})

# 研究生，能用除了c5、gJ4、gJ5以外所有节点
yjs=( "${c[@]}" "${gJ1[@]}" "${gJ3[@]}" )

# c5: 专供管理员管理集群, 不对其他用户开放
# gJ4、gJ5有更高级的显卡，需要单独开账号给受管理员批准的用户



# 有效编组：即只有写在此处的编组才会被 `all` 命令使用
server_sets=(gJ1 J1 gJ2 J2 gJ3 J3 gJ4 J4 gJ5 J5 c g a kcxm bks yjs)


# # 用不了的gpu
# INVALID_GPU=()
# export INVALID_GPU
# # 用不了的cpu
# INVALID_CPU=()
# export INVALID_CPU


