
evalarray() {
    local cmd="$1"
    shift
    "$cmd" "$@"
}

evalcmds() {
    local temp=()
    local cmdid=1
    while true; do
        if [ $# -eq 1 ]; then
            [ "$1" != '::' ] && temp+=("$1")
            eval 'local cmd'"${cmdid}"'=("${temp[@]}")'
            temp=()
            break
        elif [ "$1" = '::' ]; then
            shift
            eval 'local cmd'"${cmdid}"'=("${temp[@]}")'
            temp=()
            cmdid=$(($cmdid + 1))
        else
            temp+=("$1")
            shift
        fi
    done

    for ((i=1; i<=$cmdid; i++)); do
        declare -p cmd${i}
        eval 'local temp=("${cmd'"$i"'[@]}")'
        evalarray "${temp[@]}"
    done
}