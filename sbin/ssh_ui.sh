#!/bin/sh
# app information
PACKAGEID="com.modouwifi.vpnssh"

# get current work path
CURDIR=$(cd $(dirname $0) && pwd)

# load tp ui interfaces
. $CURDIR/../sbin/ui_tp.sh
# load mci interfaces
. $CURDIR/../sbin/mci.sh
# load dnsmasq interfaces
. $CURDIR/../sbin/dnsmasq.sh
# load pdnsd interfaces
. $CURDIR/../sbin/pdnsd.sh
# load autossh interfaces
. $CURDIR/../sbin/autossh.sh
# load vpn rules interfaces
. $CURDIR/../sbin/vpn_rule.sh
# load custom dns setting interfaces
. $CURDIR/../sbin/customdns.sh
# load redsock interfaces
. $CURDIR/../sbin/redsocks.sh

# prepare the config file for "generate-config-file" component
CUSTOMSETCONF="$CURDIR/../data/customset.conf"
DEFAULTSETCONF="$CURDIR/../conf/defaultset.conf"
[ ! -f $CUSTOMSETCONF ] && cp $DEFAULTSETCONF $CUSTOMSETCONF
# prepare for "list" component
MODELISTCONF="$CURDIR/../conf/modelist.conf"
# prepare and update the config file for "custom" component
CUSTOMCONF="$CURDIR/../conf/custom.conf"
SHELLBUTTON1="$CURDIR/../sbin/ssh_ui.sh config"
SHELLBUTTON2="$CURDIR/../sbin/ssh_ui.sh modelist"
SHELLBUTTON22="$CURDIR/../sbin/ssh_ui.sh modelist"
SHELLBUTTON3="$CURDIR/../sbin/ssh_ui.sh start"
SHELLBUTTON33="$CURDIR/../sbin/ssh_ui.sh stop"
CUSTOMPIDFILE="$CURDIR/../conf/custom.pid"
# insert custom dnsmasq config (dynamic path) to system
CUSTOMDNSMASQCONF="$CURDIR/../conf/ssh-vpn-dnsmasq.conf"
INSERTEDCUSTOMDNSMASQCONF=$SYSTEMDNSMASQDIR/ssh-vpn-dnsmasq.conf

genOrUpdateGenerateConfig()
{
  local serveraddr=`mci get modou.sshvpn.service_ip_address 2>/dev/null`
  local serverport=`mci get modou.sshvpn.port_ssh 2>/dev/null`
  local user=`mci get modou.sshvpn.user 2>/dev/null`
  local passwd=`mci get modou.sshvpn.password_ssh 2>/dev/null`
  if [ "$serveraddr" == "" ]; then
      serveraddr="0.0.0.0"
  fi
  if [ "$serverport" == "" ]; then
      serverport=0
  fi
  if [ "$user" == "" ]; then
      user="未设置"
  fi
  if [ "$passwd" == "" ]; then
      passwd="未设置"
  fi
  echo -e "服务地址: $serveraddr\n端口号: $serverport\n用户名: $user\n密码: $passwd" > $CUSTOMSETCONF
  return 0
}

genOrUpdateCustomConfig() {
  genOrUpdateGenerateConfig
  uiGenOrUpdateCustomConfig3 $CUSTOMCONF "SSH VPN" \
                             "配置账号" "${SHELLBUTTON1}" \
                             "选择模式" "${SHELLBUTTON2}" \
                             "选择模式" "${SHELLBUTTON22}" \
                             "开启服务" "${SHELLBUTTON3}" \
                             "关闭服务" "${SHELLBUTTON33}" \
                             $CUSTOMSETCONF  "autossh"
  return 0
}

# global operations
sshStartShowOnTp()
{
  genOrUpdateCustomConfig;
  custom $CUSTOMCONF &
  echo $! > $CUSTOMPIDFILE
  return 0;
}

sshTrigerConfig()
{
  genOrUpdateGenerateConfig
  generate-config-file $CUSTOMSETCONF
  local serveraddr=`head -n 1 $CUSTOMSETCONF | cut -d ' ' -f2-`;
  local serverport=`head -n 2 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
  local user=`head -n 3 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
  local passwd=`head -n 4 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
  if [ "$serveraddr" == "" ]; then
      serveraddr="0.0.0.0"
  fi
  if [ "$serverport" == "" ]; then
      serverport=0
  fi
  if [ "$user" == "" ]; then
      user="未设置"
  fi
  if [ "$passwd" == "" ]; then
      passwd="未设置"
  fi
  mci set modou.sshvpn.service_ip_address=$serveraddr
  mci set modou.sshvpn.port_ssh=$serverport
  mci set modou.sshvpn.user=$user
  mci set modou.sshvpn.password_ssh=$passwd
  local isserverstart=`uiCheckProcessStatusByName "autossh"`
  if [ "$isserverstart" == "alive" ]; then
      mci set modou.sshvpn.enable="true"
  else
      mci set modou.sshvpn.enable="false"
  fi
  mci commit
  genOrUpdateCustomConfig;
  pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
  kill -SIGUSR1 $pid >/dev/null 2>&1;
  return 0;
}

sshTrigerModeList()
{
  local index=0
  if [ "$mode" == "" -o "$mode" == "海外网站加速模式" ]; then
    index=0
  elif [ "$mode" == "海外游戏加速模式" ]; then
    index=1
  elif [ "$mode" == "完全海外模式" ]; then
    index=2
  else
    index=3
  fi
  list -t "选择模式" -s $index -c $MODELISTCONF -w $CURDIR/../sbin/
  genOrUpdateCustomConfig;
  pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
  kill -SIGUSR1 $pid >/dev/null 2>&1;
}

sshTrigerStart()
{
  local serveraddr=`mci get modou.sshvpn.service_ip_address 2>/dev/null`
  local serverport=`mci get modou.sshvpn.port_ssh 2>/dev/null`
  local user=`mci get modou.sshvpn.user 2>/dev/null`
  local passwd=`mci get modou.sshvpn.password_ssh 2>/dev/null`
  if [ "$serveraddr" == "" -o "$serverport" == "" -o "$user" == "" -o "$passwd" == "" ];then
      genOrUpdateCustomConfig;
      local pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
      kill -SIGUSR1 $pid >/dev/null 2>&1;
      return 1;
  fi
  autosshServiceStop
  autosshServiceStart $serveraddr $serverport $user $passwd
  vpnRuleStop
  vpnRuleStart
  dnsmasqAddCustomConfig $CUSTOMDNSMASQCONF
  customdnsInsert
  dnsmasqServiceReload
  pdnsdStartService
  redsocksServiceStop
  redsocksServiceStart
  sleep 1
  genOrUpdateCustomConfig;
  local pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
  kill -SIGUSR1 $pid >/dev/null 2>&1;
  local isserverstart=`uiCheckProcessStatusByName "autossh"`
  if [ "$isserverstart" == "alive" ]; then
      mci set modou.sshvpn.enable="true"
  else
      mci set modou.sshvpn.enable="false"
  fi
  mci commit
  /system/sbin/appInfo.sh set_status $PACKAGEID ISRUNNING
  return 0;
}

sshTrigerStop()
{
  dnsmasqDelCustomConfig $INSERTEDCUSTOMDNSMASQCONF
  dnsmasqServiceReload
  pdnsdStopService
  autosshServiceStop
  vpnRuleStop
  redsocksServiceStop
  genOrUpdateCustomConfig;
  pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
  kill -SIGUSR1 $pid >/dev/null 2>&1;

  local isserverstart=`uiCheckProcessStatusByName "autossh"`
  if [ "$isserverstart" == "alive" ]; then
      mci set modou.sshvpn.enable="true"
  else
      mci set modou.sshvpn.enable="false"
  fi
  mci commit
  /system/sbin/appInfo.sh set_status $PACKAGEID NOTRUNNING
  return 0;
}

case "$1" in
    "tpstart")
        sshStartShowOnTp;
        exit 0;
        ;;
    "config")
        sshTrigerConfig;
        exit 0;
        ;;
    "modelist")
        sshTrigerModeList;
        exit 0;
        ;;
    "start")
        sshTrigerStart;
        exit 0;
        ;;
    "stop")
        sshTrigerStop;
        exit 0;
        ;;
    *)
        exit 0;
        ;;
esac

