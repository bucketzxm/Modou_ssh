#!/bin/sh

CURWDIR=$(cd $(dirname $0) && pwd)

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CURDIR/lib

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop>"
    echo "example: $0 start"
}

start(){

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