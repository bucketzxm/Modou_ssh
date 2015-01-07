#!/bin/sh

server=$3
port=$4
user=$5
password=$6

CURWDIR=$(cd $(dirname $0) && pwd)
CUSTOMCONF="$CURWDIR/../conf/custom.conf"
CUSTOMBIN="/system/apps/tp/bin/custom"
PIDFILE="$CURWDIR/../conf/autossh.pid"

#SSHFLAG="-p $password $CURWDIR/../bin/ssh -L *:1080:*:22 -p $port $user@$server -F $CURWDIR/../conf/ssh_config"
SSHFLAG="-p $password $CURWDIR/../bin/ssh -D 1090 -p $port $user@$server -F $CURWDIR/../conf/ssh_config"
AUTOSSHBIN="$CURWDIR/../bin/autossh"
WRPPERSHELL="$CURWDIR/../sbin/wrpper.sh"

# set autossh Env var
export AUTOSSH_GATETIME="30"
export AUTOSSH_POLL="600"
export AUTOSSH_PATH="$WRPPERSHELL"
export AUTOSSH_PIDFILE=$PIDFILE



CMDHEAD='"cmd":"'
CMDTAIL='",'
SHELLBUTTON1="$CURWDIR/../sbin/ssh.sh config"
SHELLBUTTON2="$CURWDIR/../sbin/ssh.sh starttp"
SHELLBUTTON22="$CURWDIR/../sbin/ssh.sh stop"

CMDBUTTON1=${CMDHEAD}${SHELLBUTTON1}${CMDTAIL}
CMDBUTTON2=${CMDHEAD}${SHELLBUTTON2}${CMDTAIL}
CMDBUTTON22=${CMDHEAD}${SHELLBUTTON22}${CMDTAIL}


genCustomConfig()
{
	echo '
	{
		"title": "ssh vpn",
	' > $CUSTOMCONF

	echo '
		"button1": {

	' >> $CUSTOMCONF

	echo $CMDBUTTON1 >> $CUSTOMCONF


	
	return 0;


}



genWrpperShell(){
	echo "#!/bin/sh" > $WRPPERSHELL
	echo "export SSHPASS=$password" >> $WRPPERSHELL
	echo "$CURWDIR/../bin/sshpass -e $CURWDIR/../bin/ssh \$@" >> $WRPPERSHELL
}

start(){
	genCustomConfig
	genWrpperShell
	$CUSTOMBIN $CUSTOMCONF
	chmod +x $WRPPERSHELL

	$AUTOSSHBIN -M 7000 $SSHFLAG
}

stop(){
	pid=`cat $PIDFILE 2>/dev/null`;
    kill $pid >/dev/null 2>&1;
}

case "$1" in
    "stop")
        stop;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;

    "start")
        start;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;

    "genshell")
        genWrpperShell;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;

    *)
        usage init;
        exit 1;
        ;;
esac

