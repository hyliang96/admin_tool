#!/usr/bin/env zsh

# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
__sl_tool_dir__=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)


# 用duc统计目录下的子目录/文件 的大小，并按大小降序排列
SL() {
    [ "$(command -v duc)" = '' ] && sudo apt upudate && sudo apt -y install duc # install duc
    if [ "$(command -v duc)" = '' ]; then
            echo 'falled to install duc'
            echo 'please manually install duc'
    fi

    if [ "$1" = '--help' ] || [ '$1' = '-h' ]; then
        echo 'List size of all subdirs and files directly under a dir, sorted by size in decreasing order.'
        echo 'Usage:'
        echo '    SL -h|--help              : help'
        echo '    SL [<dir>=.]              : list <dir> without updating size data'
        echo '    SL -U|--update [<dir>=.]  : list <dir> after updating size data'
        return
    elif [ "$1" = '--update' ] || [ "$1" = '-U' ]; then
        shift
        if [ $# -eq 0 ]; then
            local dir="."
        elif [ $# -eq 1 ]; then
            local dir="$1"
        else
            SL --help
            return
        fi
        if [[ "$dir" =~ ^- ]]; then
            SL --help
            return
        fi
        sudo duc index -fHpx "$dir"
    else
        if [ $# -eq 0 ]; then
            local dir="."
        elif [ $# -eq 1 ]; then
            local dir="$1"
        else
            SL --help
            return
        fi
        if [[ "$dir" =~ ^- ]]; then
            SL --help
            return
        fi
        if [[  "$(sudo duc ls -Fg "$dir" 2>&1)" =~ 'not found in database' ]]; then
            sudo duc index -fHpx "$dir"
        fi
    fi
    sudo duc ls -Fg "$dir"
}

# 罗列/home下的用户使用情况
alias sl_home='SL /home | head -n 20'
# 罗列/data下的用户使用情况
alias sl_data='SL /data | head -n 20'
# 罗列/raid下的用户使用情况
alias sl_raid='SL /raid | head -n 20'



# 按大小升序列出当前目录下所有文件与文件夹, 单位为G的
alias _sl_watch="zsh ${__sl_tool_dir__}/slG.sh"
sl_watch()
{
    _sl_watch "$@"
}
alias sl_watch_home="sudo zsh ${__sl_tool_dir__}/slG.sh /home"

ncdu_home() {
    tmux new -s du_home 'sudo ncdu /home -x' || \
    tmux attach -t du_home
}


. ${__sl_tool_dir__}/quota/quota_du.sh
alias quota_home='quota_du'

# release this variable in the end of file
# unset -v __sl_tool_dir__
