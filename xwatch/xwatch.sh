#!/usr/bin/env bash

# get absoltae path to the dir this is in, work in bash, zsh
# if you want transfer symbolic link to true path, just change `pwd` to `pwd -P`
xwatch_dir=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)

# xwatch file
alias xwatchf="zsh $xwatch_dir/xwatch_main.sh --file"

# xwatch repeating command(s)
alias xwatchr="zsh $xwatch_dir/xwatch_main.sh --repeat"

# xwatch command(s)
alias xwatch="zsh $xwatch_dir/xwatch_main.sh"

