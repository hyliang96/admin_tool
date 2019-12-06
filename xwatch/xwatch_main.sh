#!/usr/bin/env bash

# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
here=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)



xwatch_main()
{
    # monitor a file's real time change
    if [ "$1" = '-f' ] || [ "$1" = '--file' ]; then
        shift

        local quitvim=false

        if [ "$1" = '-q' ] || [ "$1" = '--quitvim' ]; then
            local quitvim=true
            shift
        fi

        if [ $# != 1 ]; then
            echo '-f [only-one-file]'
            exit 1
        fi

        file="$1"
        if ! [ -f "$file" ]; then
            echo "$file not exits"
            exit 1
        fi
        if [ "$quitvim" = true ]; then
            command vim -u ${here}/xwatch.vim  "$@"
        else
            command vim -u ${here}/xwatch.vim -c "let g:watch_file=1"  "$@"
        fi
    else
        xwatch_parse_args "$@"
        trap ctrl_c SIGINT
        xwatch_init_dir
        xwatch_make_output
        xwatch_update_output
        xwatch_run_command
        xwatch_update_exit_listen
        xwatch_start_monitor
        wait
        xwatch_exit_script
    fi
}

xwatch_help() {
    echo 'Usage:'
    echo '    xwatch [<args>]  <command1> [<tag1>]:: <command2> [<tag2>]:: ... <commandn> [[<tagn>]::]'
    echo 'args:'
    echo '-h   --help             help'
    echo '-r   --repeat           repeatedly run commands and watch it, it contains `-s -u -c`'
    echo '-n x --interval x       time interval=x for repeatedly running commands, it is only usable for `-r`'
    echo '-c   --compact_summary  show compact summary, i.e. do not output empty lines and show tag in the same line of return'
    echo '-S   --no_summary       do not show summary of returns [after] stopping xwatch'
    echo '-U   --no_unfinished    do not show unfinished commands'\''s tags when and after xwatch'
    echo '-C   --no_command       do not show commands when watching'
    echo '-G   --no_gap           do not show a gap line between commands'\''s return'
    echo '-t   --show_tag         show tag of the commands when watching'

}

xwatch_parse_args() {
    # parse args for xwatch

    no_summary=false
    no_unfinished=false
    no_command=false
    no_gap=false
    compact_summary=false
    show_tag=false
    repeat=false
    interval=1

    set_repeat() {
        repeat=true
        no_summary=true
        no_unfinished=true
        no_command=true
        show_tag=false
    }

    while true; do
        if [[ "$1" =~ '^--' ]]; then
            if   [ "$1" = '--help' ];            then xwatch_help;         exit 0;
            elif [ "$1" = '--no_summary' ];      then no_summary=true;     shift;
            elif [ "$1" = '--no_unfinished' ];   then no_unfinished=true;  shift;
            elif [ "$1" = '--no_command' ];      then no_command=true;     shift;
            elif [ "$1" = '--no_gap' ];          then no_gap=true;         shift;
            elif [ "$1" = '--compact_summary' ]; then compact_summary=true;shift;
            elif [ "$1" = '--show_tag' ];        then show_tag=true;       shift;
            elif [ "$1" = '--repeat' ];          then set_repeat;          shift;
            elif [ "$1" = '--interval' ];        then interval="$1";       shift;
            else echo "$1 is invalid argument for \`xwatch\`";           exit 1;
            fi
        elif [[ "$1" =~ '^-' ]]; then
            for ((i=1; i<${#1}; i++)); do
                local char="${1:$i:1}"
                if   [[ "$char" =~ 'h' ]];       then xwatch_help;         exit 0;
                elif [[ "$char" =~ 'S' ]];       then no_summary=true;
                elif [[ "$char" =~ 'U' ]];       then no_unfinished=true
                elif [[ "$char" =~ 'C' ]];       then no_command=true;
                elif [[ "$char" =~ 'G' ]];       then no_gap=true;
                elif [[ "$char" =~ 'E' ]];       then compact_summary=true;
                elif [[ "$char" =~ 't' ]];       then show_tag=true;
                elif [[ "$char" =~ 'r' ]];       then set_repeat;
                elif [[ "$char" =~ 'n' ]];       then interval="$2";       shift;
                else echo "-$char is invalid argument for \`xwatch\`";   exit 1;
                fi
            done
            shift
        else
            break
        fi
    done

    # parse commands
    tags=()
    local temp=()
    local cmdid=0
    while true; do
        if [ $# -eq 0 ]; then
            if ! [ ${#temp} -eq 0 ]; then
                addcmd "$cmdid" "${temp[@]}"
                # eval 'cmd'"${cmdid}"'=("${temp[@]}")'
            fi
            if [ $cmdid = $((${#tags} + 1)) ]; then
                tag="${temp[@]}"
                tags+=("$tag")
            fi
            break
        elif [[ "$1" =~ '::$' ]]; then
            local tag="$(echo $1 | sed -E 's/::$//')"
            if [ "$tag" = '' ]; then
                tag="${temp[@]}"
            fi
            tags+=("$tag")

            shift
            addcmd "$cmdid" "${temp[@]}"
            # eval 'cmd'"${cmdid}"'=("${temp[@]}")'
            temp=()
        else
            if [ "${#temp}" -eq 0 ]; then
                cmdid=$(($cmdid + 1))
            fi
            temp+=("$1")
            shift
        fi
    done

    cmdnum=$cmdid

    # for ((i=1; i<=$cmdnum; i++)); do
    #     declare -p cmd${i}
    #     echo ${tags[$i]}
    #     echo "$(strcmd $i)"
    #     runcmd $is
    #     echo
    # done

    # declare -p cmds
    # declare -p tags
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

xwatch_init_dir() {
    rootdir=$(mktemp -d -t xwatch.XXXXXXXX)
    todo=${rootdir}/todo;       for ((i=1; i<=$cmdnum; i++)); do echo $i >> $todo; done
    finished=$rootdir/finished; touch $finished
    feedback=$rootdir/feedback; mkdir $feedback
    feedback_hot=$rootdir/feedback_hot; mkdir $feedback_hot
    output=$rootdir/output;     mkdir $output
    # echo "rootdir: $rootdir"
}


xwatch_run_command_kernel() {
    local i=
    # zsh数组从1开始，然而bash从0开始，本脚本只能在zsh运行
    for ((i=1; i<=$cmdnum; i++)); do
        (
            if [ "$1" = 'hot' ]; then
                local timestamp=$(date +%s%N)
                runcmd "$i" > ${feedback_hot}/${i}-${timestamp} 2>&1
                ln -sf ${feedback_hot}/${i}-${timestamp} ${feedback}/${i}
            else
                runcmd "$i" > ${feedback}/${i} 2>&1
            fi
            [ "$repeat" != true ] && echo $i >> $finished
            xwatch_make_output
        ) &
    done
}

xwatch_run_command() {
    if [ "$repeat" = false ]; then
        xwatch_run_command_kernel
    else
        # ( (
        while true; do
            xwatch_run_command_kernel hot
            sleep $interval
        done &
        # ) & ) > /dev/null 2>&1
    fi
}

xwatch_unfinished() {
    # unfinished
    local unfished=($(sort --version-sort $todo $finished | uniq -u))

    if [ ${#unfished} -eq 0 ]; then
        echo 'finished'
    elif [ "$no_unfinished" = false ]; then
    # unfinished中换行符换为空格
        local unfinished_tags=""
        local i=
        for i in "${unfished[@]}"; do
            local tagi="${tags[$i]}"
            if [[ "$tagi" =~ ' ' ]]; then
                tagi="'$tagi'"
            fi
            unfinished_tags="${unfinished_tags} ${tagi}"
        done
        echo "unfinished: $unfinished_tags"
    fi
}

xwatch_feedback_summary() {
    #  若 $feedback/* 不空
    # if ls $feedback/* > /dev/null 2>&1; then
        local feedbacks=($( (ls -1 $feedback/* | xargs -L1 -I{} basename {} | sort --version-sort) 2> /dev/null  ))
        local i=
        for i in "${feedbacks[@]}"; do
            # echo '--------------------------------'
            [ "$show_tag"   = true ] && [ "$compact_summary" = false ] && echo "======= ${tags[$i]} ======="
            [ "$no_command" = false ] && echo "# $(strcmd $i)"
            local result="$(cat $feedback/$i)"
            if [ "$compact_summary" = true ]; then
                local finished_cmids=($(cat ${finished}))
                # result 非全为空字符串，且 i 已完成
                if ( ! [[ "$result" =~ '^[\ \n\t\r]*$' ]] ) && \
                [ "${finished_cmids[(ie)$i]}" -le ${#finished_cmids} ]; then
                    echo "${tags[$i]}: $result"
                fi
            else
                echo "$result"
            fi
            [ "$no_gap" = false ] && echo
        done
    # fi
}

xwatch_make_output() {
    local timestamp=$(date +%s%N)
    {
        xwatch_unfinished
        xwatch_feedback_summary
    } > ${output}/writing-${timestamp}
    mv ${output}/writing-${timestamp} ${output}/writen-${timestamp}
    # ${output}/writen-${timestamp}
}

xwatch_update_output() {
    # local latest_file="$(ls -1 --sort=version ${output}/writen-* 2>/dev/null | tail -n 1)"
    local latest_file="$(ls -1 ${output}/writen-* 2>/dev/null | sort --version-sort --reverse | head -n 1)"
    if [ "$latest_file" != '' ]; then
        ln -sf ${latest_file} ${output}/read
    fi
}


xwatch_update_listen() {
    # listen for update
    while true; do
        if [ -f "${output}/quitvim" ]; then break; fi
        xwatch_update_output
        if [ -f "${output}/quitvim" ]; then break; fi

        # # if finished, add finished flag into output file
        # if [ "$(sort --version-sort $todo $finished | uniq -u)" = '' ]; then
        #     xwatch_update_output
        #     # sed -i '1s/^/vim_atuomatically_quit\n/' ${output}/output_file
        #     # echo 'vim_atuomatically_quit' >> ${output}/output_file
        #     return
        # fi

        # 不写sleep 1, 尽可能早些退出
        for i in {1..10}; do
            if [ -f "${output}/quitvim" ]; then
                return
            fi
            sleep 0.1
        done
    done
}

xwatch_exit_listen() {
    # listen for exit
    while true; do
        # 不写sleep 1, 尽可能早些退出
        for i in {1..10}; do
            if [ -f "${output}/quitvim" ]; then
                xwatch_exit_script
            fi
            sleep 0.1
        done
    done
}

xwatch_update_exit_listen() {
    {
        xwatch_update_listen
        xwatch_exit_listen
    } &
}

xwatch_exit() {
    # 杀死所有子进程
    pkill -P $$
    # 输出所有ssh返回的结果
    [ "$no_summary" = false ] && xwatch_feedback_summary
    # 报告未完成的服务器的名单
    [ "$no_unfinished" = false ] && xwatch_unfinished
    # 删除临时文件夹
    if [ -d "$rootdir" ] && rm $rootdir -rf
    unset here
}

xwatch_exit_script() {
    xwatch_exit
    # 退出程序
    exit 1
    # ( kill 0 ) > /dev/null 2>&1
}

ctrl_c() {
    xwatch_exit
    # 杀死本进程及其子进程
    kill 0
}



xwatch_start_monitor()
{
    command vim -u ${here}/xwatch.vim "${output}/read"
}



xwatch_main "$@"
