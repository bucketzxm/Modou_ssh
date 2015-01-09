#!/bin/sh

CURWDIR=$(cd $(dirname $0) && pwd)

REDSOCKSBIN="$CURWDIR/../bin/redsocks2"
REDSOCKSCONF="$CURWDIR/../conf/redsocks.conf"
PIDFILE="$CURWDIR/../conf/redsocks.pid"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CURDIR/lib

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop>"
    echo "example: $0 start"
}

start(){
    $REDSOCKSBIN -c $REDSOCKSCONF -p $PIDFILE
}

stop(){
    pid=`cat $PIDFILE 2>/dev/null`;
    kill $pid >/dev/null 2>&1;
}

case "$1" in
    "stop")
        stop;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;

    "start")
        start;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;
    *)
        usage init;
        exit 1;
        ;;
esac