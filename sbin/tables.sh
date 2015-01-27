#!/bin/sh
CURWDIR=$(cd $(dirname $0) && pwd)

LOCALPORT=${2:-1081}

DEFAULTLIST=$CURWDIR/../conf/defaultrange.txt
CUSTOMLIST=$CURWDIR/../data/customrange.txt
DEFAULTWHITE=$CURWDIR/../conf/default-whitelist.tables
DEFAULTTABLES=$CURWDIR/../conf/default.tables
SYSTEMTABLES=$CURWDIR/../conf/system.tables
IPTABLESRULE=$CURWDIR/../conf/iptables.tables

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop|genrule> localport"
    echo "example: $0 start"
}

IptablesClear()
{
    iptables -t nat -F PDNSD
    iptables -t nat -D OUTPUT -p tcp -j PDNSD
    iptables -t nat -X PDNSD
    iptables -t nat -F REDSOCKS
    iptables -t nat -D PREROUTING -p tcp -j REDSOCKS
    iptables -t nat -X REDSOCKS
}

genDefaultRule()
{
    rm $DEFAULTWHITE
    if [ ! -f "$DEFAULTLIST" ]; then
        return 0
    fi
    # add all rule to REDSOCKS Chain
    for lines in `cat $DEFAULTLIST`; do
        echo "-A REDSOCKS -d $lines -j RETURN" >> $DEFAULTWHITE
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
    fi
    echo "" >> $IPTABLESRULE
    # redirect to socket proxy prot
    echo "-A REDSOCKS -p tcp -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE
    #echo "-A REDSOCKS -p tcp --dport 80 -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE 
    #echo "-A REDSOCKS -p tcp --dport 443 -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE 
    # redirect pdns tcp connect to local port
    echo "-A PDNSD -d 8.8.8.8/32 -p tcp -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE
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

genRule()
{
    IptablesClear;
    genDefaultRule;
    genIptablesRule;    
}

stop()
{
    IptablesClear;
}

start()
{
    genRule;
    IptablesAdd;
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

    "genrule")
        genRule;
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
