#!/bin/sh

server=$2
port=$3
user=$4
password=$5

CURWDIR=$(cd $(dirname $0) && pwd)
CUSTOMCONF="$CURWDIR/../conf/custom.conf"
CUSTOMBIN="/system/apps/tp/bin/custom"

CUSTOMSETCONF="$CURWDIR/../conf/customset.conf"
SETCONF="$CURWDIR/../conf/set.conf"
DATAJSON="$CURWDIR/../conf/data.json"
# 生成密码配置文件
[ ! -f $CUSTOMSETCONF ] && cp $SETCONF 	$CUSTOMSETCONF

PIDFILE="$CURWDIR/../conf/autossh.pid"
#local network proxy
SSHFLAG="-N -D *:1090 -p $port $user@$server -F $CURWDIR/../conf/ssh_config"
#localhost proxy
#SSHFLAG="$CURWDIR/../bin/ssh -ND 1090 -p $port $user@$server -F $CURWDIR/../conf/ssh_config"
AUTOSSHBIN="$CURWDIR/../bin/autossh"
WRPPERSHELL="$CURWDIR/../sbin/wrpper.sh"

# set autossh Env var
export AUTOSSH_GATETIME="30"
export AUTOSSH_POLL="600"
export AUTOSSH_PATH="$WRPPERSHELL"
export AUTOSSH_PIDFILE=$PIDFILE

CMDHEAD='"cmd":"'
CMDTAIL='",'
SHELLBUTTON1="$CURWDIR/../sbin/ssh.sh starttp"
SHELLBUTTON2="$CURWDIR/../sbin/ssh.sh stop"
SHELLBUTTON22="$CURWDIR/../sbin/ssh.sh config"

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
	
	serveraddr=`head -n 1 $CUSTOMSETCONF | cut -d ' ' -f2-`;
	serverport=`head -n 2 $CUSTOMSETCONF | cut -d ' ' -f2-`;
	passwd=`head -n 3 $CUSTOMSETCONF | cut -d ' ' -f2-`;
	

	/system/sbin/json4sh.sh "set" $DATAJSON service_ip_address value $serveraddr
	/system/sbin/json4sh.sh "set" $DATAJSON port_ssh value $serverport
	/system/sbin/json4sh.sh "set" $DATAJSON password_ssh value $passwd

	return 0;
}



genCustomConfig()
{
	echo '
	{
		"title" : "ssh vpn",
	' > $CUSTOMCONF

	echo '
		
		"button1": {


	' >> $CUSTOMCONF

	echo $CMDBUTTON1 >> $CUSTOMCONF

	echo '
		"txt" : "启动",
		"code" : {
			"0" : "start success",
			"-1": "start failed"
		}
	},

	' >> $CUSTOMCONF

	echo '
		"button2": {
	' >> $CUSTOMCONF
	echo $CMDBUTTON2 >> $CUSTOMCONF

	echo '
		"txt" : "停止",
		"code" : {
			"0" : "stop success",
			"-1": "stop failed"

		}
	},
	' >> $CUSTOMCONF

	echo '
		"button3":{

	' >> $CUSTOMCONF
	echo $CMDBUTTON22 >> $CUSTOMCONF

	echo '
		"txt" : "配置",
		"code": {
			"0": "loading",
			"-1": "exec failed"
		}

	}

	' >> $CUSTOMCONF

	

	echo '}' >> $CUSTOMCONF
	return 0;

}

genWrpperShell(){
	echo "#!/bin/sh" > $WRPPERSHELL
	echo "export SSHPASS=$password" >> $WRPPERSHELL
	echo "$CURWDIR/../bin/sshpass -e $CURWDIR/../bin/ssh \$@" >> $WRPPERSHELL
}

starttp()
{
	genCustomConfig
	$CUSTOMBIN $CUSTOMCONF
	return 0;
}
start(){
	genWrpperShell
	chmod +x $WRPPERSHELL

	$AUTOSSHBIN -M 7000 $SSHFLAG
	return 0;
}

stop(){
	pid=`cat $PIDFILE 2>/dev/null`;
    kill $pid >/dev/null 2>&1;
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

