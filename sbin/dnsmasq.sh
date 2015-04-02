#!/bin/sh

# get current work path
local _CURDIR=$(cd $(dirname $0) && pwd)
local _SYSTEMDNSMASQDIR="/data/conf/dns"
local _CUSTOMDNSMASQCONTENT="conf-dir=$_CURDIR/../conf/dnsmasq";
local _GLOBALDNSMASQCONTENT="conf-dir=$_CURDIR/../conf/globaldnsmasq";

dnsmasqDelCustomConfig() {
    local INSERTEDCUSTOMDNSMASQCONF=$1
    rm $INSERTEDCUSTOMDNSMASQCONF 1>/dev/null 2>&1
    return 0
}

dnsmasqAddCustomConfig() {
	local CUSTOMDNSMASQCONF=$1
	local mode=`mci get modou.sshvpn.mode 2>/dev/null`
	if [ "$mode" == "全局模式" ]; then
		echo "$_GLOBALDNSMASQCONTENT" > $CUSTOMDNSMASQCONF
	else
		echo "$_CUSTOMDNSMASQCONTENT" > $CUSTOMDNSMASQCONF
	fi
    cp $CUSTOMDNSMASQCONF $_SYSTEMDNSMASQDIR 1>/dev/null 2>&1
    return 0
}

dnsmasqServiceReload() {
    /etc/init.d/dnsmasq reload
    return 0
}
