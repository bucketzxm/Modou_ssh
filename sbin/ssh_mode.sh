#!/bin/sh
# app information
PACKAGEID="com.modouwifi.vpnssh"

# get current work path
CURDIR=$(cd $(dirname $0) && pwd)

# load mci interfaces
. $CURDIR/../sbin/mci.sh
# load vpn rules interfaces
. $CURDIR/../sbin/vpn_rule.sh
# load tp ui interfaces
. $CURDIR/../sbin/ui_tp.sh

case "$1" in
    "smart")
        mci set modou.sshvpn.mode="海外网站加速模式"
        ;;
    "game")
        mci set modou.sshvpn.mode="海外游戏加速模式"
        ;;
    "global")
        mci set modou.sshvpn.mode="完全海外模式"
        ;;
    "back")
        mci set modou.sshvpn.mode="回国模式"
        ;;
    *)
        ;;
esac
mci commit
local ssh=`uiCheckProcessStatusByName "autossh"`
if [ "$ssh" == "alive" ]; then
  vpnRuleStop
  vpnRuleStart
fi
exit 0
