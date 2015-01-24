#!/bin/sh

server=$2
port=$3
user=$4
password=$5

# app information
PACKAGEID="com.modouwifi.vpnssh"

CURWDIR=$(cd $(dirname $0) && pwd)
CUSTOMCONF="$CURWDIR/../conf/custom.conf"
CUSTOMBIN="/system/apps/tp/bin/custom"
CUSTOMPIDFILE="$CURDIR/../conf/custom.pid"

CUSTOMSETCONF="$CURWDIR/../conf/customset.conf"
SETCONF="$CURWDIR/../conf/set.conf"
DATAJSON="$CURWDIR/../conf/data.json"

ROTATELOGS="$CURWDIR/../bin/rotatelogs"
LOG="$CURWDIR/../ssh.log 100K"
ROTATELOGSFLAG="-t"

# 生成密码配置文件
[ ! -f $CUSTOMSETCONF ] && cp $SETCONF  $CUSTOMSETCONF

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

CMDHEAD='"cmd":"'
CMDTAIL='",'
SHELLBUTTON1="$CURWDIR/../sbin/ssh.sh config"
SHELLBUTTON2="$CURWDIR/../sbin/ssh.sh start"
SHELLBUTTON22="$CURWDIR/../sbin/ssh.sh stop"

CMDBUTTON1=${CMDHEAD}${SHELLBUTTON1}${CMDTAIL}
CMDBUTTON2=${CMDHEAD}${SHELLBUTTON2}${CMDTAIL}
CMDBUTTON22=${CMDHEAD}${SHELLBUTTON22}${CMDTAIL}

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop|genrule|starttp|config> server port username password"
    echo "example: $0 starttp"
}


config()
{
    generate-config-file $CUSTOMSETCONF

    server=`head -n 1 $CUSTOMSETCONF | cut -d ' ' -f2-`;
    port=`head -n 2 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;
    user=`head -n 3 $CUSTOMSETCONF | tail -n 1 |  cut -d ' ' -f2-`;
    password=`head -n 4 $CUSTOMSETCONF | tail -n 1 | cut -d ' ' -f2-`;

    #命令中用的是port,user,server,这里直接重新赋值一下

    /system/sbin/json4sh.sh "set" $DATAJSON service_ip_address value $server
    /system/sbin/json4sh.sh "set" $DATAJSON port_ssh value $port
    /system/sbin/json4sh.sh "set" $DATAJSON user value $user
    /system/sbin/json4sh.sh "set" $DATAJSON password_ssh value $password

    genCustomConfig;
    pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
    return 0;
}


REDSOCKSCONF="$CURWDIR/../conf/redsocks.conf"
genRedSocksConfig()
{

    server=`/system/sbin/json4sh.sh "get" $DATAJSON server_ip_address value`
    port=`/system/sbin/json4sh.sh "get" $DATAJSON port_ssh value`
    user=`/system/sbin/json4sh.sh "get" $DATAJSON user value`
    password=`/system/sbin/json4sh.sh "get" $DATAJSON password_ssh value`

    echo '

        base{
            log_debug=off;
            log_info=off;
            log="file:
    ' >$REDSOCKSCONF

    $REDSOCKSCONF >> $REDSOCKSCONF;
    echo ';' >> $REDSOCKSCONF
    echo '

            daemon=on;
            redirector=iptables;
            }
    ' >> $REDSOCKSCONF

    echo '
        redsocks {
            local_ip = 192.168.1.1;
            local_port =
    ' >> $REDSOCKSCONF
    $port >> $REDSOCKSCONF
    echo ';' >>$REDSOCKSCONF
    echo '
        type=socks5;
        autoproxy=1;
        timeout=5;
    '
}

startRedSocks()
{
    iptables -t nat -N REDSOCKS
    iptables -t nat -A PREROUTING -i br-lan -p tcp -j REDSOCKS

    #do not redirect traffic to the followign address ranges
    iptables -t nat -A REDSOCKS -d 127.0.0.0/8 -j RETURN
    iptables -t nat -A REDSOCKS -d 192.18.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 10.8.0.0/16 -j RETURN
    iptables -t nat -A REDSOCKS -d 224.0.0.0/4 -j RETURN
    iptables -t nat -A REDSOCKS -d 240.0.0.0/4 -j RETURN

    # Redirect normal HTTP and HTTPS traffic
    iptables -t nat -A REDSOCKS -p tcp --dport 80 -j REDIRECT --to-ports 11111
    iptables -t nat -A REDSOCKS -p tcp --dport 443 -j REDIRECT --to-ports 11111
    $CURWDIR/../bin/redsocks2;

}

genCustomConfig()
{
    # title   : "SSH VPN"
    # content : dynamic generated (contains setting info)
    # button1 : "账号配置"
    # button2 : "开启/关闭服务" (dynamic switch)
    echo '
    {
        "title" : "SSH VPN",
    ' > $CUSTOMCONF

	  local content=`genCustomContentByName "ssh" "insertinfo" $CUSTOMSETCONF`
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
    local isserverstart=`checkProcessStatusByName "ssh"`
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
            "code": {"0": "start success", "-1": "执行失败"}
            }
    }
    ' >> $CUSTOMCONF
    return 0;
}

checkProcessStatusByName()
{
	local $processname=$1
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
    return 0;
}


starttp()
{
    genCustomConfig
    $CUSTOMBIN $CUSTOMCONF
    echo $! > $CUSTOMPIDFILE
    return 0;
}

start(){
    if [ ! $server ]; then
        server=`/system/sbin/json4sh.sh get $DATAJSON service_ip_address value`
    fi
    if [ ! $port ]; then
        port=`/system/sbin/json4sh.sh get $DATAJSON port_ssh value`
    fi
    if [ ! $user ]; then
        user=`/system/sbin/json4sh.sh get $DATAJSON user value`
    fi
    if [ ! $password ]; then
        password=`/system/sbin/json4sh.sh get $DATAJSON password_ssh value`
    fi
    export OPENSSH_PASSWORD=$password
    SSHFLAG="-N -D *:1080 $user@$server -p $port -F $CURWDIR/../conf/ssh_config"
    $AUTOSSHBIN -M 7000 $SSHFLAG 2>&1 | $ROTATELOGS $ROTATELOGSFLAG $LOG &
    genRedSocksConfig
    $CURDIR/../sbin/pdns.sh start
    $CURDIR/../sbin/redsocks.sh start
    $CURDIR/../sbin/tables.sh start
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
    $CURDIR/../sbin/pdns.sh stop
    $CURDIR/../sbin/redsocks.sh stop
    $CURDIR/../sbin/tables.sh stop

    sleep 1
    genCustomConfig;
    pid=`cat $CUSTOMPIDFILE 2>/dev/null`;
    kill -SIGUSR1 $pid >/dev/null 2>&1;
    /system/sbin/appInfo.sh set_status $PACKAGEID NOTRUNNING
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
        exit 0;
        ;;
    "config" ):
        config;
        exit 0;
        ;;

    * )
        usage init;;
esac

