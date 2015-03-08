#!/bin/sh
# app information
PACKAGEID="com.modouwifi.vpnss"

# get current work path
local _CURDIR=$(cd $(dirname $0) && pwd)
# custom special website
local _CUSTOMDNS_DATA="$_CURDIR/../data/customdns.conf"
local _CUSTOMDNS="$_CURDIR/../conf/dnsmasq/customdns.conf"
local _CUSTOMDNS_TMP="$_CURDIR/../conf/dnsmasq/customdns_tmp.conf"

# load mci interfaces
. $_CURDIR/../sbin/mci.sh

customdnsInsert(){
  [ -f $_CUSTOMDNS_DATA ] && cp $_CUSTOMDNS_DATA $_CUSTOMDNS
  local customone=`mci get modou.ssvpn.customdns 2>/dev/null`
  if [ "$customone" == "" -o "customdns" = "参考格式:google.com" ]; then
    return 0
  else
    echo -e "server=/$customone/127.0.0.1#5353" > $_CUSTOMDNS_TMP
    dnsmasq -C /var/etc/dnsmasq.conf --test 1>/dev/null 2>&1
    if [ "$?" != "0" ]; then
      rm $_CUSTOMDNS_TMP
      mci set modou.ssvpn.customdns="格式错误:$customone"
      mci commit
    else
      local test=`echo $customone | grep ':'`
      if [ "$test" != "" ]; then
        rm $_CUSTOMDNS_TMP
        mci set modou.ssvpn.customdns="格式错误:$customone"
        mci commit
        return 0
      fi
      rm $_CUSTOMDNS_TMP
      echo -e "server=/$customone/127.0.0.1#5353" >> $_CUSTOMDNS
      cp $_CUSTOMDNS $_CUSTOMDNS_DATA
      mci set modou.ssvpn.customdns="成功添加:$customone"
      mci commit
    fi
  fi
  return 0
}
