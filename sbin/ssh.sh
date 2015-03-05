#!/bin/sh

server=$2
port=$3
user=$4
password=$5




CURWDIR=$(cd $(dirname $0) && pwd)

# app information
PACKAGEID="com.modouwifi.vpnssh"

#load mci config
. $CURWDIR/../sbin/mci.sh 

# since the app framework bug
[ -f $CURWDIR/../data ] && rm $CURWDIR/../data
[ ! -d $CURWDIR/../data/ ] && mkdir $CURWDIR/../data/

# prepare the config file for "generate-config-file" component
CUSTOMSETCONF="$CURWDIR/../data/customset.conf"
SETCONF="$CURWDIR/../conf/set.conf"
[ ! -f $CUSTOMSETCONF ] && cp $SETCONF $CUSTOMSETCONF

# prepare for rotatelogs
ROTATELOGS="$CURWDIR/../bin/rotatelogs"
LOG="$CURWDIR/../ssh.log 100K"
ROTATELOGSFLAG="-t"

# prepare for autossh
PIDFILE="$CURWDIR/../conf/autossh.pid"
#local network proxy
SSHFLAG="-N -D *:1090 -p $port $user@$server -F $CURWDIR/../conf/ssh_config"
AUTOSSHBIN="$CURWDIR/../bin/autossh"

# set autossh Env var
export AUTOSSH_GATETIME="30"
export AUTOSSH_POLL="600"
export AUTOSSH_PATH="$CURWDIR/../bin/sshp"
export AUTOSSH_PIDFILE=$PIDFILE
export OPENSSH_PASSWORD=$password

# prepare and update the config file for "custom" component
CUSTOMCONF="$CURWDIR/../conf/custom.conf"
CUSTOMBIN="/system/apps/tp/bin/custom"
CUSTOMPIDFILE="$CURWDIR/../conf/custom.pid"
CMDHEAD='"cmd":"'
CMDTAIL='",'
SHELLBUTTON1="$CURWDIR/../sbin/ssh.sh config"
SHELLBUTTON2="$CURWDIR/../sbin/ssh.sh start"
SHELLBUTTON22="$CURWDIR/../sbin/ssh.sh stop"

SHELLBUTTON3="$CURWDIR/../sbin/ssh.sh configMode"

CMDBUTTON1=${CMDHEAD}${SHELLBUTTON1}${CMDTAIL}
CMDBUTTON2=${CMDHEAD}${SHELLBUTTON2}${CMDTAIL}
CMDBUTTON22=${CMDHEAD}${SHELLBUTTON22}${CMDTAIL}
CMDBUTTON3=${CMDHEAD}${SHELLBUTTON3}${CMDTAIL}


DATAJSON="$CURWDIR/../conf/data.json"
usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop|genrule|starttp|config> server port username password"
    echo "example: $0 starttp"
}

genCustomConfig()
{
    # title   : "SSH VPN"
    # content : dynamic generated (contains setting info)
    # button1 : "账号配置"
    # button2 : "开启/关闭服务" (dynamic switch)
    # button3 : "切换模式"
    echo '
    {
        "title" : "SSH VPN",
    ' > $CUSTOMCONF

      local content=`genCustomContentByName "autossh" "insertinfo" $CUSTOMSETCONF`
      echo $content >> $CUSTOMCONF
    echo '
        "button1": {
    ' >> $CUSTOMCONF
    echo $CMDBUTTON1 >> $CUSTOMCONF
    echo '
            "txt": "应用配置",
            "code": {"0": "正在显示", "-1": "执行失败"}
            },
        "button2": {
    ' >>$CUSTOMCONF
    local isserverstart=`checkProcessStatusByName "autossh"`
    if [ "$isserverstart" == "alive" ]; then
        echo $CMDBUTTON22 >> $CUSTOMCONF
        echo '
            "txt": "关闭服务",
        ' >> $CUSTOMCONF
    else
        echo $CMDBUTTON2 >> $CUSTOMCONF
        echo '
            "txt": "开启服务",
        ' >> $CUSTOMCONF
    fi
    echo '
            "code": {"0": "执行成功", "-1": "执行失败"}
            },
    
    ' >> $CUSTOMCONF

    echo '
        "button3": {
    ' >> $CUSTOMCONF

    echo $CMDBUTTON3 >> $CUSTOMCONF
    echo '
        "txt" : "选择模式",
    ' >> $CUSTOMCONF

    echo $CMDBUTTON3 >>$CUSTOMCONF
    echo '
        "code": {"0": "执行成功","-1":"执行失败"}
        }
    }
    ' >> $CUSTOMCONF    
    return 0;
}

checkProcessStatusByName()
{
    local processname=$1
    local status=`ps | grep $processname | wc -l`
    if [ $status == "1" ]; then
        echo "dead";
    else
        echo "alive";
    fi
    return 0;
}


# operations for generate a "custom" component configfile
# usage:  genCustomContentByName "ss-redir" "insertinfo" infofile
#         genCustomContentByName "ss-redir" "noinsertinfo"
genCustomContentByName()
{
    [ "$#" != "3" ] && return 1
    local processname="$1"
    local isinsertinfo="$2"
    local infofile="$3"
    local contenthead='"content":"'
    local contenttail='",'
    local contentbody=""
    local linetag="\n"
    isserverstart=`checkProcessStatusByName $processname`
    if [ "$isserverstart" == "alive" ]; then
        contentbody="**服务已启动**"
    else
        contentbody="**服务未启动**"
    fi
    # insert the custom setting info to the content if necessarry
    # but should pay attention to the '\n'
    if [ "$isinsertinfo" == "insertinfo" ]; then
        local counts=`cat $infofile | wc -l`
        local configcontent=""
        for count in $(seq $counts)
        do
            line=`head -n $count $infofile | tail -n 1`
            configcontent=${configcontent}${line}${linetag}
        done
        contentbody=${contentbody}${linetag}${configcontent};
    fi
    echo ${contenthead}${contentbody}${contenttail};
    return ;
}

starttp()
{
    genCustomConfig
    $CUSTOMBIN $CUSTOMCONF &
    echo $! > $CUSTOMPIDFILE
    return 0;
}

start(){
    if [ ! $server ]; then
        #server=`/system/sbin/json4sh.sh get $DATAJSON service_ip_address value`
		server=`mci get modou.sshvpn.service_ip_address 2>/dev/null`
    fi
    if [ ! $port ]; then
        #port=`/system/sbin/json4sh.sh get $DATAJSON port_ssh value`
		server=`mci get modou.sshvpn.port_ssh 2>/dev/null`
    fi
    if [ ! $user ]; then
        #user=`/system/sbin/json4sh.sh get $DATAJSON user value`
		user=`mci get modou.sshvpn.user 2>/dev/null`
    fi
    if [ ! $password ]; then
        #password=`/system/sbin/json4sh.sh get $DATAJSON password_ssh value`
		password=`mci get modou.sshvpn.password_ssh 2>/dev/null`
    fi
    export OPENSSH_PASSWORD=$password
    SSHFLAG="-N -D *:1080 $user@$server -p $port -F $CURWDIR/../conf/ssh_config"
    $AUTOSSHBIN -M 7000 $SSHFLAG 2>&1 | $ROTATELOGS $ROTATELOGSFLAG $LOG &
    #genRedSocksConfig
    $CURWDIR/../sbin/pdns.sh start
    $CURWDIR/../sbin/redsocks.sh start
    $CURWDIR/../sbin/tables.sh start
    sleep 1
    genCustomConfig;
    local pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
    /system/sbin/appInfo.sh set_status $PACKAGEID ISRUNNING
    return 0;
}

stop(){
    pid=`cat $PIDFILE 2>/dev/null`;
    kill $pid >/dev/null 2>&1;
    $CURWDIR/../sbin/pdns.sh stop
    $CURWDIR/../sbin/redsocks.sh stop
    $CURWDIR/../sbin/tables.sh stop

    sleep 1
    genCustomConfig;
    pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
    /system/sbin/appInfo.sh set_status $PACKAGEID NOTRUNNING
    return 0
}

configMode()
{
	P=`cat $CURWDIR/../conf/mode.conf`
	if [ -n $P ]; then
		P=0;
	fi
    list -t "选择模式" -s $P -c $CURWDIR/../conf/modeList.conf 
    
}
config()
{
    generate-config-file $CUSTOMSETCONF
    server=`head -n 1 $CUSTOMSETCONF | cut -d ' ' -f2-`;
    port=`head -n 2 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
    user=`head -n 3 $CUSTOMSETCONF | tail -n 1 |  cut -d ' ' -f2-`;
    password=`head -n 4 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;

    #命令中用的是port,user,server,这里直接重新赋值下,方便调试
    #/system/sbin/json4sh.sh "set" $DATAJSON service_ip_address value $server
    #/system/sbin/json4sh.sh "set" $DATAJSON port_ssh value $port
    #/system/sbin/json4sh.sh "set" $DATAJSON user value $user
    #/system/sbin/json4sh.sh "set" $DATAJSON password_ssh value $password
	mci set modou.sshvpn.service_ip_address=$server
	mci set modou.sshvpn.port_ssh=$port
	mci set modou.sshvpn.user=$user
	mci set modou.sshvpn.password_ssh=$password

    local isserverstart=`checkProcessStatusByName "autossh"`
    if [ "$isserverstart" == "alive" ]; then
        #/system/sbin/json4sh.sh "set" $DATAJSON state_ssh value true
		mci set modou.sshvpn.state_ssh="true"
    else
        /system/sbin/json4sh.sh "set" $DATAJSON state_ssh value false
		mci set modou.sshvpn.state_ssh="false"
    fi
    genCustomConfig;
    pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
    return 0;
}

syncConfigFromDataToTp()
{
    #local server=`/system/sbin/json4sh.sh get $DATAJSON service_ip_address value`
    #local port=`/system/sbin/json4sh.sh get $DATAJSON port_ssh value`
    #local user=`/system/sbin/json4sh.sh get $DATAJSON user value`
    #local password=`/system/sbin/json4sh.sh get $DATAJSON password_ssh value`
	local server=`mci get modou.sshvpn.service_ip_address 2>/dev/null`
	local server=`mci get modou.sshvpn.port_ssh 2>/dev/null`
	local user=`mci get modou.sshvpn.user 2>/dev/null`
	local password=`mci get modou.sshvpn.password_ssh 2>/dev/null`
    if [ "$server" == "" ]; then
        server="0.0.0.0"
    fi
    if [ "$port" == "" ]; then
        port=0
    fi
    if [ "$user" == "" ]; then
        user="未设置"
    fi
    if [ "$password" == "" ]; then
        password="未设置"
    fi
    # FIXME
    echo "服务地址: $server 
端口号: $port
用户名: $user
密码: $password" > $CUSTOMSETCONF

	return 0;
}

syncConfigFromTpToData()
{
    local server=`head -n 1 $CUSTOMSETCONF | cut -d ' ' -f2-`;
    local port=`head -n 2 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
    local user=`head -n 3 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
    local password=`head -n 4 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
    if [ "$server" == "" ]; then
        serveraddr="0.0.0.0"
    fi
    if [ "$port" == "" ]; then
        serverport=0
    fi
    if [ "$user" == "" ]; then
        secmode="未设置"
    fi
    if [ "$password" == "" ]; then
        passwd="未设置"
    fi

    #/system/sbin/json4sh.sh "set" $DATAJSON service_ip_address value $server
    #/system/sbin/json4sh.sh "set" $DATAJSON port_ssh value $port
    #/system/sbin/json4sh.sh "set" $DATAJSON user value $user
    #/system/sbin/json4sh.sh "set" $DATAJSON password_ssh value $password
	mci set modou.sshvpn.service_ip_address=$server
	mci set modou.sshvpn.port_ssh=$port
	mci set modou.sshvpn.user=$user
	mci set modou.sshvpn.password_ssh=$password
    local isserverstart=`checkProcessStatusByName "autossh"`
    if [ "$isserverstart" == "alive" ]; then
        #/system/sbin/json4sh.sh "set" $DATAJSON state_ssh value true
		mci set modou.sshvpn.state_ssh="true"
    else
        #/system/sbin/json4sh.sh "set" $DATAJSON state_ssh value false
		mci set modou.sshvpn.state_ssh="false"
    fi
	mci commit
    return 0

}
case "$1" in

    "stop" )
        stop;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;
    #start ---> start ssh (second step)
    "start" )
        start;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;

    "genshell" )
        genWrpperShell;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;
    # start ---> start tp ( first step)
    "starttp"):
        starttp;
		if [[ "0" != "$?" ]]; then
			exit1;
		fi
        exit 0;
        ;;
    "config" ):
        config;
        exit 0;
        ;;
    "syncConfig" ):
        syncConfigFromDataToTp;
        exit 0;
        ;;
    "restoreConfig")
        syncConfigFromTpToData;
        exit 0;
        ;;
    "configMode")
        configMode;
        exit 0;
        ;;  
    * )
        usage init;;
esac
