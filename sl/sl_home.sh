#!/usr/bin/env zsh

# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
__sl_tool_dir__=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)

# 罗列home下的用户使用情况
duc_home() {
    sudo su -c bash <<-EOF
[ "$(command -v duc)" = '' ] &&   apt upudate &&   apt -y install duc # install duc
if [ "$(command -v duc)" = '' ]; then
    echo 'falled to install duc'
else
    # [ ! -e /root/.duc.db ]
    [[  "$(sudo su -c 'duc ls -Fg /home' 2>&1)" =~ 'Database not found' ]] &&  duc index -fHpx /home
    duc ls -Fg /home
fi
EOF
}

alias sl_home='duc_home'

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
