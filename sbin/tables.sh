#!/bin/sh
CURWDIR=$(cd $(dirname $0) && pwd)

LOCALPORT=${2:-1081}
VPNMODE=$1

DEFAULTLIST=$CURWDIR/../conf/defaultrange.txt
DEFAULTTABLES=$CURWDIR/../conf/default.tables
SYSTEMTABLES=$CURWDIR/../conf/system.tables
IPTABLESRULE=$CURWDIR/../conf/iptables.tables

CHINARANGE=$CURWDIR/../conf/chinarange.txt
CHINASETFILE=$CURWDIR/../conf/chinaset.ipset
FILTERCHAIN="REDSOCKS"
CHINASET="chinaset"

usage()
{
    echo "ERROR: action missing"
    echo "syntax: $0 <start|stop|genrule|gameMode|globalMode|smartMode|backMode> localport"
    echo "example: $0 start"
}

IptablesClear()
{
    iptables -t nat -F PDNSD 1>/dev/null 2>&1
    iptables -t nat -D OUTPUT -p tcp -j PDNSD 1>/dev/null 2>&1
    iptables -t nat -X PDNSD 1>/dev/null 2>&1
    iptables -t nat -F $FILTERCHAIN 1>/dev/null 2>&1
    iptables -t nat -D PREROUTING -i br-lan -p tcp -j $FILTERCHAIN 1>/dev/null 2>&1
    iptables -t nat -X $FILTERCHAIN 1>/dev/null 2>&1
}

genChinaSet(){
    if [ ! -f "$CHINARANGE" ]; then
        return 0
    fi
    # create chinaset ipset
    echo "create $CHINASET hash:net family inet">$CHINASETFILE
    # add all localnet to ipset
    echo "add $CHINASET 0.0.0.0/8">>$CHINASETFILE
    echo "add $CHINASET 127.0.0.0/8">>$CHINASETFILE
    echo "add $CHINASET 10.0.0.0/8">>$CHINASETFILE
    echo "add $CHINASET 192.168.0.0/16">>$CHINASETFILE
    echo "add $CHINASET 172.16.0.0/12">>$CHINASETFILE
    # add all net to ipset
    for lines in `cat $CHINARANGE`; do
        echo "add $CHINASET $lines">>$CHINASETFILE
    done
    echo "gen $CHINASETFILE ok"
    return 0
}

IpSetAdd(){
    ipset destroy $CHINASET
    cat $CHINASETFILE | ipset restore
}

genIptablesRule(){
    # add system iptables
    iptables-save -t nat > $SYSTEMTABLES
    # delete last 2 line
    sed 'N;$!P;$!D;$d' $SYSTEMTABLES > $IPTABLESRULE

    # add default tables
    echo "" >> $IPTABLESRULE
    cat $DEFAULTTABLES >> $IPTABLESRULE

    case "$VPNMODE" in
        "start")
            genSmartRule;
            ;;
        "genrule")
            genSmartRule;
            ;;
        "gameMode")
            genGameRule;
            ;;
        "globalMode")
            genGlobalRule;
            ;;
        "smartMode")
            genSmartRule;
            ;;
        "backMode")
            genBackRule;
            ;;
        *)
            return 1;
            ;;
    esac

    # redirect pdns tcp connect to local port
    echo "-A PDNSD -d 8.8.8.8/32 -p tcp -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE
    echo "COMMIT" >> $IPTABLESRULE

}

genGameRule(){
    #游戏模式 局域网->白名单->redsocks
    # add chinaset ipset rule
    echo "" >> $IPTABLESRULE
    if [ -f "$CHINASETFILE" ]; then
        echo "-A $FILTERCHAIN -m set --match-set $CHINASET dst -j RETURN" >> $IPTABLESRULE
    fi
    # redirect to socket proxy prot
    echo "-A $FILTERCHAIN -p tcp -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE
}

genGlobalRule(){
    #全局模式，所有tcp包都重定向到 redsocks
    # add chinaset ipset rule
    echo "" >> $IPTABLESRULE
    if [ -f "$CHINASETFILE" ]; then
        echo "-A $FILTERCHAIN -p tcp -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE
    fi
}

genSmartRule(){
    # 智能模式 国内ip  和  tcp port 80 + tcp port 442 重定向到redsocks
    # add chinaset ipset rule
    echo "" >> $IPTABLESRULE
    if [ -f "$CHINASETFILE" ]; then
        echo "-A $FILTERCHAIN -m set --match-set $CHINASET dst -j RETURN" >> $IPTABLESRULE
    fi
    # redirect to socket proxy prot
    echo "-A $FILTERCHAIN -p tcp --dport 80 -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE 
    echo "-A $FILTERCHAIN -p tcp --dport 443 -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE 
}

genBackRule(){
    # add chinaset ipset rule
    echo "" >> $IPTABLESRULE
    if [ -f "$CHINASETFILE" ]; then
        echo "-A $FILTERCHAIN -m set --match-set $CHINASET dst -p tcp -j REDIRECT --to-ports $LOCALPORT" >> $IPTABLESRULE
    fi
}

IptablesAdd(){
    if [ ! -f "$IPTABLESRULE" ]; then
        return 1
    fi
    iptables-restore $IPTABLESRULE
    return 0
}

genRule(){
    genChinaSet;
    genIptablesRule;
}

stop(){
    IptablesClear;
}

start(){
    IptablesClear;
    genRule;
    IpSetAdd;
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
    "gameMode")
        start;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;
    "globalMode")
        start;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;
    "smartMode")
        start;
        if [[ "0" != "$?" ]]; then
            exit 1;
        fi
        exit 0;
        ;;
    "backMode")
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