#!/bin/sh

local _CURDIR=$(cd $(dirname $0) && pwd)

local _REDSOCKSBIN="$_CURDIR/../bin/redsocks"
local _REDSOCKSCONF="$_CURDIR/../conf/redsocks.conf"
local _PIDFILE="$_CURDIR/../conf/redsocks.pid"
local _ROTATELOGS="$_CURDIR/../bin/rotatelogs"
local _LOG="$_CURDIR/../redsocks.log 100K"
local _ROTATELOGSFLAG="-t"


redsocksServiceStart(){
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$_CURDIR/../lib
    $_REDSOCKSBIN -c $_REDSOCKSCONF -p $_PIDFILE 2>&1 | $_ROTATELOGS $_ROTATELOGSFLAG $_LOG &
}

redsocksServiceStop(){
    killall redsocks
}

#case "$1" in
#    "stop")
#        stop;
#        if [[ "0" != "$?" ]]; then
#            exit 1;
#        fi
#        exit 0;
#        ;;
#
#    "start")
#        start;
#        if [[ "0" != "$?" ]]; then
#            exit 1;
#        fi
#        exit 0;
#        ;;
#    *)
#        usage init;
#        exit 1;
#        ;;
#esac
