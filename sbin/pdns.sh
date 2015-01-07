#!/bin/sh
CURWDIR=$(cd $(dirname $0) && pwd)

PDNSDBIN="$CURWDIR/../bin/pdnsd"
PDNSDCONF="conf-dir=$CURWDIR/../conf/dnsmasq";
DNSMASQCONF="$CURWDIR/../conf/ssh-vpn-dnsmasq.conf"
TODNSMASQCONF="/data/conf/dns/ssh-vpn-dnsmasq.conf"

addConfDir() {
    echo "$PDNSDCONF" > $DNSMASQCONF
    cp $DNSMASQCONF $TODNSMASQCONF 1>/dev/null 2>&1
}

delConfDir() {
    rm $TODNSMASQCONF
}

dnsReload() {
    /etc/init.d/dnsmasq reload
}

start(){
    addConfDir
    dnsReload
}

stop(){
    delConfDir
    killall pdnsd 1>/dev/null 2>&1
    dnsReload
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

    *)
        usage init;
        exit 1;
        ;;
esac