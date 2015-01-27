#!/bin/sh
CURWDIR=$(cd $(dirname $0) && pwd)

PDNSDBIN="$CURWDIR/../bin/pdnsd"
PDNSDCONF="conf-dir=$CURWDIR/../conf/dnsmasq";
DNSMASQCONF="$CURWDIR/../conf/ssh-vpn-dnsmasq.conf"
TODNSMASQCONF="/data/conf/dns/ssh-vpn-dnsmasq.conf"
PIDFILE="$CURWDIR/../conf/pdnsd.pid"
PDNSDCONFILE="$CURWDIR/../conf/pdnsd.conf"

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

pdnsStart(){
    chown matrix $PDNSDCONFILE 1>/dev/null 2>&1
    $PDNSDBIN -c $PDNSDCONFILE &
    echo $! > $PIDFILE
}

start(){
    addConfDir
    dnsReload
    pdnsStart
}

stop(){
    delConfDir
    pid=`cat $PIDFILE 2>/dev/null`;
    kill $pid >/dev/null 2>&1;
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
