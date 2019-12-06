#!/usr/bin/env bash


admin_tool_path=$(cd "$(dirname "${BASH_SOURCE[0]-$0}")"; pwd)
admin_tool_path="`echo ${admin_tool_path} | sed 's/^\/mfs\/\([^\/]\+\)/\/home\/\1\/mfs/'`"


