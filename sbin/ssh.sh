#!/bin/sh

server=$3
port=$4
user=$5
password=$6

CURWDIR=$(cd $(dirname $0) && pwd)
CUSTOMCONF="$CURWDIR/../conf/custom.conf"
PIDFILE="$CURWDIR/../conf/autossh.pid"

#SSHFLAG="-p $password $CURWDIR/../bin/ssh -L *:1080:*:22 -p $port $user@$server -F $CURWDIR/../conf/ssh_config"
SSHFLAG="-p $password $CURWDIR/../bin/ssh -D 1090 -p $port $user@$server -F $CURWDIR/../conf/ssh_config"
AUTOSSHBIN="$CURWDIR/../bin/autossh"

# set autossh Env var
export AUTOSSH_GATETIME="30"
export AUTOSSH_POLL="600"
export AUTOSSH_PATH="$CURWDIR/../bin/ssh"
export AUTOSSH_PIDFILE=$PIDFILE
export OPENSSH_PASSWORD=$password

start(){
	$AUTOSSHBIN -M 7000 $SSHFLAG
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

