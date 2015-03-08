#!/bin/sh

# get current work path
local _CURDIR=$(cd $(dirname $0) && pwd)
local _PDNSDBIN="$_CURDIR/../bin/pdnsd"
local _PDNSDCONFILE="$_CURDIR/../conf/pdnsd.conf"
local _PDNSDPIDFILE="$_CURDIR/../conf/pdnsd.pid"

pdnsdStartService() {
    chown matrix $_PDNSDCONFILE 1>/dev/null 2>&1
    $_PDNSDBIN -c $_PDNSDCONFILE &
    return 0
}

pdnsdStopService() {
    killall pdnsd 1>/dev/null 2>&1
    return 0
}
