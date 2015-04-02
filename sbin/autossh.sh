#!/bin/sh

# get current work path
local _CURDIR=$(cd $(dirname $0) && pwd)
local _AUTOSSHBIN="$_CURDIR/../bin/autossh"
local _PIDFILE="$_CURDIR/../conf/autossh.pid"
local _ROTATELOGS="$_CURDIR/../bin/rotatelogs"
local _LOG="$_CURDIR/../ssh.log 100K"
local _ROTATELOGSFLAG="-t"



autosshServiceStop()
{
	  local autosshpid=`cat $_PIDFILE 2>/dev/null`
	  kill -9 $autosshpid 1>/dev/null 2>&1
    killall sshp 2>/dev/null
    return 0
}

autosshServiceStart()
{
    local serveraddr=$1
    local serverport=$2
    local user=$3
    local passwd=$4
    export AUTOSSH_GATETIME="30"
    export AUTOSSH_POLL="600"
    export AUTOSSH_PATH="$_CURDIR/../bin/sshp"
    export AUTOSSH_PIDFILE=$_PIDFILE
    export OPENSSH_PASSWORD=$passwd

    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$_CURDIR/../lib
    local SSHFLAG="-N -D *:1080 -p $serverport $user@$serveraddr -F $_CURDIR/../conf/ssh_config"
    $_AUTOSSHBIN -M 7000 $SSHFLAG 2>&1 | $_ROTATELOGS $_ROTATELOGSFLAG $_LOG &
    return 0
}
