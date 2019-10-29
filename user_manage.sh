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

manual_set() {
    # local username_=
    local realname_=
    local uid_=
    # echo -n 'set username: ' >&2 ; read -r username_
    echo -n 'set realname: ' >&2 ; read -r realname_
    echo -n 'set uid: ' >&2 ; read uid_
    local password=

    while true; do
        local answer=$(bash -c "read  -n 1 -p 'randomly inititalize password? [Y|N]' c; echo \$c"); echo
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
        local password="$(randpasswd)"
    else
        while true; do
            echo -n 'set password: ' >&2 ; read -sr password; echo '' >&2
            echo -n 'check password: ' >&2 ; read -sr password2; echo '' >&2
            if [ "$password" = "$password2" ]; then
                break
            else
                echo 'passwords are not the same, re-input it' >&2
            fi
        done
    fi

    local enc_password_=$(echo "$password" | openssl passwd -1 -stdin)

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


allnewkey() {
    if [ $# -ne 2 ]; then
        echo 'Usage: `allnewkey <server_set> <username>`
What it will do:
    regernate ~/.ssh/{id_rsa,id_rsa.pub} for <username>
    add id_rsa.pub to ~/.ssh/authorized_keys
    send ~/.ssh to all servers in <server_set>'
        return
    fi


    local server_set="$1"
    local username="$2"


    echo "=================== making keys in /home/$username/.ssh  ====================="
    # 若已有id_rsa,id_rsa.pub，则会询问你是否覆盖之
    su - $username -c 'ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa -q && \
     cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys'

    echo; echo; echo
    echo "======= distributing /home/$username/.ssh to server set [${server_set}] ========"
    # 会覆盖各个服务器上的原文件
    send /home/$username/.ssh  "${server_set}:/home/$username/"
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

_alladduser()
{
    if [ "$1" = "-h" ] || [ "$1" = "--help" ] || [ "$1" = "help" ]  || \
        ! ( [ $# -eq 1 ]  || [ $# -eq 4 ] ) ; then
        echo 'Usage:
* interactively:    `alladduser <username>[@<server_set> default=a]`
    realname can contains English letters in low/captital case, chinese characters, `'\''``. `"`,-,_ ,sapce,etc
* non-interactively: `alladduser <username>[@<server_set> default=a] <realname> <uid> <enc_password>`
    the enc_password is gotten by
        method1      `openssl passwd -1`         to encrypted the password
        method2      `sudo cat /etc/shadow`      the 2nd part (segmented by ":") is encrypted user password
Attention:
    * please set user'\''s uid the same on all server machines, or authorization will wrong under mfs folder
    * generate random password: `openssl rand -base64 24`  24-letter, on 64-bit machine' >&2
        return
    fi

    local username="$(echo $1 | awk -F@ '{printf $1}')"
    local server_set="$(echo $1 | awk -F@ '{printf $2}')"
    shift
    if [ "$server_set"  = '' ]; then
        local server_set='a'
    fi

    echo "username: $username"
    echo "server_set: $server_set"

    if [ $# -eq 3 ]; then
        local realname="$1"
        local uid="$2"
        local enc_password="$3"
        local passwd='已加密'
    else
        local realname=
        local uid=
        local enc_password=
        local passwd=
        manual_set realname uid enc_password passwd
    fi

    echo "============================ making user account  ============================"
    all "$server_set" "$(adduser_command $username $realname $uid $enc_password)"

    local servers=()
    parse_server_set "$server_set" servers

    ssh "${servers[1]}" -t ". $admin_tool_path/load.sh && allnewkey '$server_set' $username"

    userguide "$username" "$passwd" "${servers[*]}"
}

alladduser()
{
    if [ $# -eq 0 ]; then
        sudo su -c ". $admin_tool_path/load.sh; _alladduser"
    else
        local user_server_set="$1"
        set -- ${@:2:$#}
        sudo su -c ". $admin_tool_path/load.sh; _alladduser '$user_server_set' $*"
    fi
}

alldeluser()
{
    if [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = 'help' ] || [ $# -ne 1 ]; then
        echo "alldeluser <user_name>@<host_set> "
        return
    fi

    local user=$(echo $1 | awk -F@ '{printf $1}')
    local hostset=$(echo $1 | awk -F@ '{printf $2}')
    if [ "$hostset" = '' ]; then
        echo "alldeluser <user_name>@<host_set> "
        return
    fi

    answer=$(bash -c "read -p $'You want to delete \e[1;31m$user\e[0m in host set \e[1;31m$hostset\e[0m? It\'s \e[1;31mirreversible\e[0m. [Y/N]' c; echo \$c"); echo
    if [ "$answer" = "y" ] || [ "$answer" = "Y" ]; then
        sudo su -c ". $admin_tool_path/load.sh; all '$hostset' 'userdel -r $user; id $user'"
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


allpasswd()
{
    if ( [ $# -ne 1 ] &&  [ $# -ne 2 ] ) || [ "$1" = '-h' ] || [ "$1" = '--help' ] || [ "$1" = 'help' ]; then
        echo 'Usage: change password for a <user> on all host in <host_set>'
        echo 'allpasswd <user>@<host_set>  : set new password interactively'
        echo 'allpasswd <user>@<host_set> <source_host>  : set password follow <source_host>'
        return
    fi
    local user=$(echo $1 | awk -F@ '{printf $1}')
    local server_set=$(echo $1 | awk -F@ '{printf $2}')
    shift

    echo $user
    echo $server_set

    if [ $# -ne 0 ]; then
        local source_host="$1"
        echo $source_host
    else
        local servers=()
        parse_server_set "$server_set" servers
        local source_host=${servers[1]}
        ssh -t $source_host passwd $user
    fi

    local encrypted="$(ssh -t $source_host "cat /etc/shadow | grep $user | awk -F: '{ printf \$2}'")"
    all "$server_set" "usermod -p '${encrypted}' $user"
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
