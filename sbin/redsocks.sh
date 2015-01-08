#!/bin/sh

CURWDIR=$(cd $(dirname $0) && pwd)

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop>"
    echo "example: $0 start"
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