#!/bin/sh
CURWDIR=$(cd $(dirname $0) && pwd)


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

    "genrule")
        genRule;
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