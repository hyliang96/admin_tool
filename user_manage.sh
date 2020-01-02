#!/usr/bin/env bash
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
. $here/utils.sh

# 生成随机密码
randpasswd()
{
    if [ "$1" = help ] || [ "$1" = '--help' ] || [ "$1" = '-h' ]; then
        echo "Usage: \`randpasswd [length]\` to generate random passwod of this length"
        return
    fi
    if [ $# -eq 0 ]; then
        local len=24
    else
        local len=$1
    fi
    openssl rand -base64 $len
}

get_password() {
    local password1=

    while true; do
        local answer=$(bash -c "read -p 'randomly inititalize password? [Y|N]' c; echo \$c"); echo
        if [ "$answer" = 'y' ] ||  [ "$answer" = 'Y' ]; then
            local random_password=true
            break
        elif  [ "$answer" = 'n' ] ||  [ "$answer" = 'N' ]; then
            local random_password=false
            break
        fi
        echo 'input not correct, please input "N" or "Y".'
    done

    if [ "$random_password" = 'true' ]; then
        local password1="$(randpasswd)"
    else
        while true; do
            echo -n 'set password: ' >&2 ; read -sr password1; echo '' >&2
            echo -n 'check password: ' >&2 ; read -sr password2; echo '' >&2
            if [ "$password1" != "$password2" ]; then
                echo 'passwords are not the same, re-input it' >&2
            elif [ "$password1" = '' ] || [ "$password1" = $"\n" ]; then
                echo 'password cannot be empty' >&2
            else
                break
            fi
        done
    fi

    eval $1=\"\$password1\"
}

encypher() {
    local password="$1"
    echo "$password" | openssl passwd -6 -stdin
}

manual_set() {
    # local username_=
    local realname_=
    local uid_=
    # echo -n 'set username: ' >&2 ; read -r username_
    echo -n 'set realname: ' >&2 ; read -r realname_
    echo -n 'set uid: ' >&2 ; read uid_

    local password
    get_password password
    local enc_password_="$(encypher "$password")"

    # eval $1=\"\$username_\"
    eval $1=\"\$realname_\"
    eval $2=\"\$uid_\"
    eval $3=\"\$enc_password_\"
    eval $4=\"\$password\"
}

adduser_command() {


    local username=$1
    local realname=$2
    local uid=$3
    local enc_password=$4


    username=${username//\'/\'\\\'\'}
    username=${username//\"/\'\\\"\'}
    realname=${realname//\'/\'\\\'\'}
    realname=${realname//\"/\'\\\"\'}
    enc_password=${enc_password//\'/\'\\\'\'}
    enc_password=${enc_password//\"/\'\\\"\'}

    echo -E "useradd '$username' -m -c '$realname' -s /usr/bin/zsh -u $uid && usermod --password '$enc_password' '$username'"
    echo

    unset username
    unset realname
    unset uid
    unset enc_password
}

allsendssh__() {
    local username="$1"
    local server_set="$2"
    send /home/$username/.ssh  "${server_set}:/home/$username/"
}

parse_username_server() {
    local username_=$(echo $1 | awk -F@ '{printf $1}')
    local server_set_=$(echo $1 | awk -F@ '{printf $2}')

    local error_=false
    if [ "$username_" = '' ]; then
        echo 'empty username' >&2
        local error_=true
    fi
    if [ "$server_set_" = '' ]; then
        echo 'empty server_set' >&2
        local error_=true
    fi

    eval $2=\"\$username_\"
    eval $3=\"\$server_set_\"
    eval $4=\"\$error_\"

    # echo username_: $username_
    # echo server_set_: $server_set_
    # echo error_: $error_
}

allsendssh_() {
    if [ $# -ne 2 ] || [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = 'help' ]; then
        echo 'Usage:'
        echo 'allpasswd <username>@<host_set>  <source_host>:  send <source_host>:/home/<username>/.ssh to <host_set>'
        return
    fi

    local username server_set error
    parse_username_server "$1" username server_set error
    [ "$error" = true ] && { echo && allsendssh_ -h; return; }

    local source_host="$2"
    local source_ssh="$(ssh $source_host "ls -d /home/${username}/.ssh")"
    if [ "$source_ssh" = '' ]; then
        echo "dir not found: $source_host:/home/${username}/.ssh/" >&2
        return
    fi

    echo
    echo username: $username
    echo server_set: $server_set
    echo source_host: $source_host

    local answer=$(bash -c "read -p 'the info above are correct ? [Y|N]' c; echo \$c"); echo
    if ! ( [ "$answer" = Y ] || [ "$answer" = 'y' ] ); then
        echo "You chose info not correct. Endding"
        return
    fi

    # allow authorization agent in this command
    eval `ssh-agent -s`
    ssh-add
    ssh -A -t $source_host ". $admin_tool_path/load.sh  && allsendssh__ '$username' '$server_set'"
    # remove all keys
    ssh-add -D
}

allsendssh() {
    local user_server_set="$1"
    # local source_host="$2"
    set -- ${@:2:$#}
    sudo su -c ". $admin_tool_path/load.sh && allsendssh_ '$user_server_set' $*"
}

allnewkey() {
    if [ $# -ne 2 ]; then
        echo 'Usage: `allnewkey <server_set> <username>`
What it will do:
    regernate ~/.ssh/{id_rsa,id_rsa.pub} for <username>
    send ~/.ssh to all servers in <server_set>
It wont do:
    add id_rsa.pub to ~/.ssh/authorized_keys'
        return
    fi

    local server_set="$1"
    local username="$2"


    echo "=================== making keys in /home/$username/.ssh  ====================="
    # 若已有id_rsa,id_rsa.pub，则会询问你是否覆盖之
    su - $username -c 'ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa -q'
     # cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys'

    echo; echo; echo
    echo "======= distributing /home/$username/.ssh to server set [${server_set}] ========"
    # 会覆盖各个服务器上的原文件
    allsendssh__ "$username" "$server_set"
}


userguide()
{
    local username="$1"
    local passwd="$2"
    local servers="$3"

    echo "-------------------------------------------------------------------------"
    echo "服务器账号：$username"
    echo "密码：$passwd     登录后可自行改密"
    echo "开了账号的服务器：$servers"
    echo
    echo "服务器使用教程：http://101.6.240.88:4567/tutorial/Cluster-Usage"
    echo "教程账号：user，密码：linearregression"
    echo "-------------------------------------------------------------------------"
}

parse_user_info()
{
    local username="$1"; shift
    echo username = "$username"
    for i in "${@}"; do
        echo -E "$i"
    done

    # 分辨模式
    if [ $# -eq $((5 + 3)) ]; then
        local interactive=false
        local expand=false
    elif [ $# -eq $((5 + 1)) ]; then
        local interactive=false
        local expand=true
    elif [ $# -eq 5 ]; then
        while true; do
            local interactive=true
            local expand=$(bash -c "read -p 'expand existing account to new servers? [Y|N]' c; echo \$c")
            if [ "$expand" = 'Y' ] || [ "$expand" = 'y' ]; then
                expand=true;  break
            elif [ "$expand" = 'N' ] || [ "$expand" = 'n' ]; then
                expand=false; break
            else
                echo "please input Y or N\n" >&2
            fi
        done
    else
        echo "error: args in parse_user_info" >&2
        return
    fi

    # 获得信息
    local info_realname=
    local info_uid=
    local info_enc_password=
    local info_passwd=
    local info_source_host=


    if [ "$expand" = true ]; then
        while true; do
            if [ "$interactive" = true ]; then
                local info_source_host=$(bash -c "read -p 'realneme, uid, password, .ssh/ follow which server ? ' c; echo \$c")
            else
                local info_source_host="$6"
            fi
            local info_uid="$(ssh $info_source_host "cat /etc/passwd | grep $username | awk -F: '{ printf \$3 }'")"
            if [[ "$info_uid" =~ "^[0-9]+$" ]]; then
                break
            else
                echo "error: host $info_source_host has no user $username; please input a valid server\n" >&2
                [ "$interactive" = false ] && return
            fi
        done
    fi

    if [ "$expand" = true ]; then
        local info_realname="$(ssh $info_source_host "cat /etc/passwd | grep $username | awk -F: '{ printf \$5 }'")"
        local info_uid="$(ssh $info_source_host "cat /etc/passwd | grep $username | awk -F: '{ printf \$3 }'")"
        # local info_uid="$(ssh $info_source_host "id $username | grep -Eo 'uid=[0-9]+' | grep -Eo '[0-9]+'")"
        local info_enc_password="$(ssh -t $info_source_host "cat /etc/shadow | grep $username | awk -F: '{ printf \$2}'")"
        local info_passwd="follows $info_source_host"
    fi

    if [ "$expand" = false ] && [ "$interactive" = false ]; then
        local info_realname="$6"
        local info_uid="$7"
        local info_enc_password="$8"
        local info_passwd='已加密'
    fi

    if [ "$expand" = false ] && [ "$interactive" = true ]; then
        manual_set info_realname info_uid info_enc_password info_passwd
    fi

    echo -E info_realname: $info_realname
    echo -E info_uid: $info_uid
    echo -E info_enc_password: $info_enc_password
    echo -E info_passwd: $info_passwd
    echo -E info_source_host: $info_source_host

    eval $1=\"\$info_realname\"
    eval $2=\"\$info_uid\"
    eval $3=\"\$info_enc_password\"
    eval $4=\"\$info_passwd\"
    eval $5=\"\$info_source_host\"
}

_alladduser()
{
    echo $#
    for i in "$@"; do
        echo -E "$i"
    done
    echo '----------'

    if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]  || \
        ! ( [ $# -eq 1 ] || [ $# -eq 2 ] || [ $# -eq 4 ] ) ; then
        echo 'Usage:
* interactively:    `alladduser <username>@<server_set>`
    realname can contains English letters in low/captital case, chinese characters, `'\''``. `"`,-,_ ,sapce,etc
* non-interactively: `alladduser <username>@<server_set>  <source_host> : realname, uid, password, .ssh/ all follow <source_host>`
* non-interactively: `alladduser <username>@<server_set>  <realname> <uid> <enc_password>`
    the enc_password is gotten by
        method1      `openssl passwd -1`         to encrypted the password
        method2      `sudo cat /etc/shadow`      the 2nd part (segmented by ":") is encrypted user password
Attention:
    * please set user'\''s uid the same on all server machines, or authorization will wrong under mfs folder
    * generate random password: `openssl rand -base64 24`  24-letter, on 64-bit machine' >&2
        return
    fi



    # local username="$(echo $1 | awk -F@ '{printf $1}')"
    # local server_set="$(echo $1 | awk -F@ '{printf $2}')"
    # shift
    # if [ "$server_set"  = '' ]; then
        # local server_set='a'
    # fi

    local username server_set error
    parse_username_server "$1" username server_set error
    [ "$error" = true ] && { echo &&  _alladduser -h; return; }
    shift

    echo "username: $username"
    echo "server_set: $server_set"

    local realname uid enc_password passwd source_host
    # local result="$(
    local parse_command='parse_user_info '"$username"' realname uid enc_password passwd source_host'
    for i in "$@"; do parse_command+=" '$i'" ; done
    eval "$parse_command"

    echo realname: $realname
    echo uid: $uid
    echo enc_password: $enc_password
    echo passwd: $passwd
    echo source_host: $source_host

    # return

    echo "============================ making user account  ============================"
    all "$server_set" "$(adduser_command $username $realname $uid $enc_password)"

    echo
    echo
    echo "========================== send /home/<user>/.ssh/  =========================="
    local servers=()
    parse_server_set "$server_set" servers

    # allow authorization agent in this command
    eval `ssh-agent -s`
    ssh-add
    if [ "$source_host" != '' ]; then
        ssh -A "$source_host" -t ". $admin_tool_path/load.sh && allsendssh__ $username '$server_set'"
    else
        ssh -A "${servers[1]}" -t ". $admin_tool_path/load.sh && allnewkey '$server_set' $username"
    fi
    # remove all keys
    ssh-add -D

    userguide "$username" "$passwd" "${servers[*]}"
}

alladduser()
{
    if [ $# -eq 0 ]; then
        sudo su -c ". $admin_tool_path/load.sh; _alladduser"
    else
        local args=''; for i in "$@"; do args+="'$i' "; done
        sudo su -c ". $admin_tool_path/load.sh; _alladduser ${args}"
    fi
}

alldeluser()
{
    if [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = 'help' ] || [ $# -ne 1 ]; then
        echo "alldeluser <user_name>@<host_set> "
        return
    fi

    local user hostset error
    parse_username_server "$1" user hostset error
    [ "$error" = true ] && { echo && alldeluser -h; return; }

    answer=$(bash -c "read -p $'You want to delete \e[1;31m$user\e[0m in host set \e[1;31m$hostset\e[0m? It\'s \e[1;31mirreversible\e[0m. [Y/N]' c; echo \$c"); echo
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        sudo su -c ". $admin_tool_path/load.sh; all '$hostset' 'userdel -r $user' 'id $user'"
        # echo "userdel -r $user"
    elif [ "$answer" = "n" ] || [ "$answer" = "N" ]; then
        echo 'please correct the last command'
    else
        echo 'input Y/y or N/n please!'
    fi
}

# 列出你本地可见的用户名
alias userls='cut -d: -f1 /etc/passwd'

# show uid of all users on this server
ids()
{
    if [ $# -eq 0 ]; then
        awk -F '[:]' '{print $3, $1}' /etc/passwd | sort -nr
    else
        awk -F '[:]' '{print $3, $1}' /etc/passwd | sort -nr | head -n$1
    fi
}

gid()
{
    if [ $# -eq 0 ]; then
        getent group | awk -F '[:]' '{print $3, $1":"$2":"$4}' | sort -n
    else
        getent group $@
    fi
}

# set uid for a user on all servers
allsetuid()
{
    if [ $# -eq 3 ]; then
        local server_set="$1"; shift
    else
        local server_set='a'
    fi
    local username="$1"
    local uid="$2"
    all "$server_set" "usermod -u $uid $username && groupmod -g $uid $username"
}


allpasswd_()
{
    if ( [ $# -ne 1 ] &&  [ $# -ne 2 ] ) || [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = 'help' ]; then
        echo 'Usage: change password for a <username> on all host in <host_set>'
        echo 'allpasswd <username>@<host_set>  : set new password interactively'
        echo 'allpasswd <username>@<host_set> <source_host>  : set password follow <source_host>'
        return
    fi

    local username server_set error
    parse_username_server "$1" username server_set error
    [ "$error" = true ] && { echo &&  allpasswd_ -h; return; }
    shift

    echo username: $username
    echo server_set: $server_set

    if [ $# -ne 0 ]; then
        local follow=true
        local source_host="$1"
    else
        while true; do
            local answer=$(bash -c "read  -n 1 -p 'follow the password of an existing server? [Y|N]' c; echo \$c"); echo
            if [ "$answer" = 'y' ] ||  [ "$answer" = 'Y' ]; then
                local follow=true
                local source_host=$(bash -c "read -p 'input a host alias: ' c; echo \$c")
                break
            elif  [ "$answer" = 'n' ] ||  [ "$answer" = 'N' ]; then
                local follow=false
                break
            fi
            echo 'input not correct, please input "N" or "Y".'
        done

    fi

    if [ "$follow" = true ]; then
        echo follows: $source_host
        local password="follows $source_host"
    else
        local servers=()
        parse_server_set "$server_set" servers
        local source_host=${servers[1]}

        local password
        get_password password
        local enc_password="$(encypher "$password")"

        ssh $source_host "usermod --password '$enc_password' '$username'"
        # ssh -t $source_host passwd $username
    fi

    local encrypted="$(ssh -t $source_host "cat /etc/shadow | grep $username | awk -F: '{ printf \$2}'")"
    all "$server_set" "usermod -p '${encrypted}' $username"

    userguide "$username" "$password" "${servers[*]}"
}

allpasswd()
{
    local user_server_set="$1"
    set -- ${@:2:$#}
    sudo su -c ". $admin_tool_path/load.sh; allpasswd_ '$user_server_set' $*"
}


# 原生用户操作
# 详见 man adduser, man useradd, man userdel 等

# To list all users capable of authenticating (in some way), including non-local, see this reply: https://askubuntu.com/a/414561/571941

# 加用户
    # 傻瓜操作，需要设置密码，会创建/home/用户名，等其他众多设置，
    # `sudo adduser 用户名`
    # 底层操作，需要设置密码，不创建/home/用户名，等其他众多设置
    # `sudo useradd 用户名`
    # See also: What is the difference between adduser and useradd?

# 删用户
        # `sudo userdel 用户名`
        # `sudo rm -r /home/用户名`       # 小心使用，或用下命令
        # `sudo rm -rf /var/mail/用户名`   # 小心使用，或用下命令
    # 上述操作等价于
    # `sudo userdel -r 用户名`

# 改用户名
    # usermod -l 新用户名 老用户名

# 改用户密码
    # sudo passwd 用户名

# 改用默认shell
    # sudo chsh 用户名

# 改用户信息 （如真实姓名）:
    # sudo chfn 用户名

# 将用户加入sudo
    # usermod -aG sudo 用户名
