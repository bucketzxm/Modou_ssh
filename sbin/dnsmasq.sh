#!/bin/sh

# get current work path
local _CURDIR=$(cd $(dirname $0) && pwd)
local _SYSTEMDNSMASQDIR="/data/conf/dns"
local _CUSTOMDNSMASQCONTENT="conf-dir=$_CURDIR/../conf/dnsmasq";

dnsmasqDelCustomConfig() {
    local INSERTEDCUSTOMDNSMASQCONF=$1
    rm $INSERTEDCUSTOMDNSMASQCONF 1>/dev/null 2>&1
    return 0
}

dnsmasqAddCustomConfig() {
    local CUSTOMDNSMASQCONF=$1
    echo "$_CUSTOMDNSMASQCONTENT" > $CUSTOMDNSMASQCONF
    cp $CUSTOMDNSMASQCONF $_SYSTEMDNSMASQDIR 1>/dev/null 2>&1
    return 0
}

dnsmasqServiceReload() {
    /etc/init.d/dnsmasq reload
    return 0
}
