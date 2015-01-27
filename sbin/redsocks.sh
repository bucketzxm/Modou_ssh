#!/bin/sh

CURWDIR=$(cd $(dirname $0) && pwd)

REDSOCKSBIN="$CURWDIR/../bin/redsocks"
REDSOCKSCONF="$CURWDIR/../conf/redsocks.conf"
PIDFILE="$CURWDIR/../conf/redsocks.pid"
ROTATELOGS="$CURWDIR/../bin/rotatelogs"
LOG="$CURWDIR/../redsocks.log 100K"
ROTATELOGSFLAG="-t"
#ROTATELOGSFLAG="-t -p $CURWDIR/s.sh"

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CURWDIR/../lib

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop>"
    echo "example: $0 start"
}

start(){
    $REDSOCKSBIN -c $REDSOCKSCONF -p $PIDFILE 2>&1 | $ROTATELOGS $ROTATELOGSFLAG $LOG &
}

stop(){
#   pid=`cat $PIDFILE 2>/dev/null`;
#   kill $pid >/dev/null 2>&1;
    killall redsocks
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