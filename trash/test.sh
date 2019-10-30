
cmd_for_server()
{
    local server="$1"
    local cmd_name="$2"

    if [ "$checkuid" = true ] || [ "$checkgid" = true ]; then
        local id_cmd=''
        if [ "$checkuid" = true ]; then
            id_cmd+="\$(ssh '$server' \"id '$uid' 2>&1\"  | grep -v 'no such user')     "
        fi
        if [ "$checkgid" = true ]; then
            id_cmd+="\$(ssh '$server' \"getent group '$gid'\")"
        fi
        local local_cmds=("echo  \"${id_cmd}\"")
    elif [ "$send" = 'true' ]; then
        local local_cmds=(command rsync -aHhzP -e "ssh -o 'StrictHostKeyChecking no'" "${files[@]}" "$server:$server_path")
    else
        local local_cmds=(command ssh -o 'StrictHostKeyChecking=no' "$server" "$cmds")
    fi
    declare -p local_cmds
    echo "${cmd_name}"'=("${local_cmds[@]}")'
    eval "${cmd_name}"'=("${local_cmds[@]}")'
}




addcmd() {
    local cmdid=$1; shift

    if [ $# -eq 1 ]; then
        local cmd=("${@}")
    else
        local cmd=()
        for arg in "$@"; do
            if [[ "$arg" =~ ' ' ]] || [[ "$arg" =~ $'\t' ]] ||  [[ "$arg" =~ $'\n' ]]; then
                cmd+=("'${arg//'/'\\''}'")
            else
                cmd+=("${arg}")
            fi
        done
    fi

    eval 'cmd'"${cmdid}"'=("${cmd[@]}")'
}

runcmd() {
    local cmdid="$1"
    eval 'local temp=("${cmd'"$cmdid"'[@]}")'
    eval "${temp[@]}"
}

strcmd() {
    local cmdid="$1"
    eval 'local temp=("${cmd'"$cmdid"'[@]}")'
    echo "${temp[@]}"
}

server=g1
cmds="echo -E \"# ls\""

# cmds='echo -E "# echo \"hello world\""; echo "hello world"'

checkuid=false
checkgid=false
uid=haoyu
gid=haoyu

send=false
files=('trash/send_all.sh' 'trash/asd\ asd' 'a')
server_path="."

cmds=''
for i in "$@"; do
    if [ "$no_prompt" = true ]; then
        cmds="${cmds} $i; echo;"
    else
        i_print="${i//\\/\\\\}"
        i_print="${i_print//\`/\\\`}"
        i_print="${i_print//\$/\\\$}"
        i_print="${i_print//\"/\\\"}"
        cmds="${cmds} echo -E \"# $i_print\"; $i; echo;"
    fi
done

cmd_for_server "$server" cmd
declare -p cmd
addcmd 1 "${cmd[@]}"
runcmd 1



