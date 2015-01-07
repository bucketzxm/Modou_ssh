#!/bin/sh
CURWDIR=$(cd $(dirname $0) && pwd)

SERVERADDR=$2
LOCALPORT=$3

EFAULTLIST=$CURWDIR/../conf/defaultrange.txt
CUSTOMLIST=$CURWDIR/../data/customrange.txt
DEFAULTWHITE=$CURWDIR/../conf/default-whitelist.tables
DEFAULTTABLES=$CURWDIR/../conf/default.tables
SYSTEMTABLES=$CURWDIR/../conf/system.tables
IPTABLESRULE=$CURWDIR/../conf/iptables.tables

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop> serveraddress localport"
    echo "example: $0 start"
}

IptablesClear()
{
    iptables -t nat -F PDNSD
    iptables -t nat -D OUTPUT -p tcp -j PDNSD
    iptables -t nat -X PDNSD
    iptables -t nat -F SSH
    iptables -t nat -D PREROUTING -p tcp -j SSH
    iptables -t nat -X SSH
}

genDefaultRule()
{
    if [ ! -f "$DEFAULTLIST" ]; then
        return 1
    fi
    # add all rule to SHADOWSOCKS Chain
    rm $DEFAULTWHITE
    for lines in `cat $DEFAULTLIST`; do
        echo "-A SSH -d $lines -j RETURN" >> $DEFAULTWHITE
    done
    return 0
}

genIptablesRule()
{
    # add system iptables
    iptables-save -t nat > $SYSTEMTABLES
    # delete last 2 line
    sed 'N;$!P;$!D;$d' $SYSTEMTABLES > $IPTABLESRULE
    # add default tables
    echo "" >> $IPTABLESRULE
    cat $DEFAULTTABLES >> $IPTABLESRULE
    # add defaultlist
    if [ -f "$DEFAULTLIST" ]; then
        echo "" >> $IPTABLESRULE
        cat $DEFAULTWHITE >> $IPTABLESRULE
        echo "-A SSH -p tcp -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE
    fi
    # ignore server addr
    echo "-I SSH -d $SERVERADDR -j RETURN"  >> $IPTABLESRULE
    echo "COMMIT" >> $IPTABLESRULE
}

IptablesAdd()
{
    if [ ! -f "$IPTABLESRULE" ]; then
        return 1
    fi
    iptables-restore $IPTABLESRULE
    return 0
}

stop()
{
	IptablesClear;
}

start()
{
	IptablesClear;
	genDefaultRule;
	genIptablesRule;
	IptablesAdd;
}

case "$1" in
	"stop")
	    stop;
		if [ "0" != "$?" ];then
			exit 1;
		fi
		exit 0;
		;;

	"start")
		start;
		if ["0" != "$?" ];then
			exit 1;
		fi
		exit 0;
		;;

	*)
		usage init;
		exit 1;
		;;
esac