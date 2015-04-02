#!/bin/sh
CURDIR=$(cd $(dirname $0) && pwd)
. $CURDIR/../sbin/mci.sh
local _LOCALPORT=${2:-1081}
local _FILTERCHAIN="REDSOCKS"
local _CHINASET="chinaset"
local _LOCALNETSET="localnet"
local _CHINARANGE=$CURDIR/../conf/chinarange.txt
local _CHINASETFILE=$CURDIR/../conf/chinaset.ipset
local _LOCALNETSETFILE=$CURDIR/../conf/localnetset.ipset
local _DEFAULTTABLES=$CURDIR/../conf/default.tables
local _SYSTEMTABLES=$CURDIR/../conf/system.tables
local _IPTABLESRULE=$CURDIR/../conf/iptables.tables

vpnIptablesClear(){
    iptables -t nat -F PDNSD 1>/dev/null 2>&1
    iptables -t nat -D OUTPUT -p tcp -j PDNSD 1>/dev/null 2>&1
    iptables -t nat -X PDNSD 1>/dev/null 2>&1
    iptables -t nat -F $_FILTERCHAIN 1>/dev/null 2>&1
    iptables -t nat -D ALLOW_RULES -i br-lan -p tcp -j $_FILTERCHAIN 1>/dev/null 2>&1
    iptables -t nat -X $_FILTERCHAIN 1>/dev/null 2>&1
}

vpnGenLocalNetIpSet(){
    # create chinaset ipset
    echo "create $_LOCALNETSET hash:net family inet">$_LOCALNETSETFILE
    # add all localnet to ipset
    echo "add $_LOCALNETSET 0.0.0.0/8"     >>$_LOCALNETSETFILE
    echo "add $_LOCALNETSET 127.0.0.0/8"   >>$_LOCALNETSETFILE
    echo "add $_LOCALNETSET 10.0.0.0/8"    >>$_LOCALNETSETFILE
    echo "add $_LOCALNETSET 192.168.0.0/16">>$_LOCALNETSETFILE
    echo "add $_LOCALNETSET 172.16.0.0/12" >>$_LOCALNETSETFILE
    return 0
}

vpnGenChinaIpSet(){
    if [ ! -f "$_CHINARANGE" ]; then
        return 0
    fi
    # create chinaset ipset
    echo "create $_CHINASET hash:net family inet">$_CHINASETFILE
    # add all localnet to ipset
    #echo "add $_CHINASET 0.0.0.0/8"     >>$_CHINASETFILE
    #echo "add $_CHINASET 127.0.0.0/8"   >>$_CHINASETFILE
    #echo "add $_CHINASET 10.0.0.0/8"    >>$_CHINASETFILE
    #echo "add $_CHINASET 192.168.0.0/16">>$_CHINASETFILE
    #echo "add $_CHINASET 172.16.0.0/12" >>$_CHINASETFILE
    # add all net to ipset
    for lines in `cat $_CHINARANGE`; do
        echo "add $_CHINASET $lines"    >>$_CHINASETFILE
    done
    return 0
}

vpnIpSetAdd(){
    ipset destroy $_LOCALNETSET
    cat $_LOCALNETSETFILE | ipset restore
    ipset destroy $_CHINASET
    cat $_CHINASETFILE | ipset restore
}

vpnGenIptablesRule_smartMode(){
    # add system iptables
    iptables-save -t nat > $_SYSTEMTABLES
    # delete last 2 line
    sed 'N;$!P;$!D;$d' $_SYSTEMTABLES > $_IPTABLESRULE

    # add default tables
    echo "" >> $_IPTABLESRULE
    cat $_DEFAULTTABLES >> $_IPTABLESRULE

    # add localnet ipset rule
    echo "" >> $_IPTABLESRULE
    if [ -f "$_LOCALNETSETFILE" ]; then
        echo "-A $_FILTERCHAIN -m set --match-set $_LOCALNETSET dst -j RETURN" >> $_IPTABLESRULE
    fi

    # add chinaset ipset rule
    echo "" >> $_IPTABLESRULE
    if [ -f "$_CHINASETFILE" ]; then
        echo "-A $_FILTERCHAIN -m set --match-set $_CHINASET dst -j RETURN" >> $_IPTABLESRULE
    fi
    # redirect to socket proxy prot
    echo "-A $_FILTERCHAIN -p tcp --dport 80 -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    echo "-A $_FILTERCHAIN -p tcp --dport 443 -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    # redirect pdns tcp connect to local port
    echo "-A PDNSD -d 8.8.8.8/32 -p tcp -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    echo "COMMIT" >> $_IPTABLESRULE
}

vpnGenIptablesRule_gameMode(){
    # add system iptables
    iptables-save -t nat > $_SYSTEMTABLES
    # delete last 2 line
    sed 'N;$!P;$!D;$d' $_SYSTEMTABLES > $_IPTABLESRULE

    # add default tables
    echo "" >> $_IPTABLESRULE
    cat $_DEFAULTTABLES >> $_IPTABLESRULE

    # add localnet ipset rule
    echo "" >> $_IPTABLESRULE
    if [ -f "$_LOCALNETSETFILE" ]; then
        echo "-A $_FILTERCHAIN -m set --match-set $_LOCALNETSET dst -j RETURN" >> $_IPTABLESRULE
    fi

    # add chinaset ipset rule
    echo "" >> $_IPTABLESRULE
    if [ -f "$_CHINASETFILE" ]; then
        echo "-A $_FILTERCHAIN -m set --match-set $_CHINASET dst -j RETURN" >> $_IPTABLESRULE
    fi
    # redirect to socket proxy prot
    echo "-A $_FILTERCHAIN -p tcp -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    # redirect pdns tcp connect to local port
    echo "-A PDNSD -d 8.8.8.8/32 -p tcp -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    echo "COMMIT" >> $_IPTABLESRULE
}

vpnGenIptablesRule_globalMode(){
    # add system iptables
    iptables-save -t nat > $_SYSTEMTABLES
    # delete last 2 line
    sed 'N;$!P;$!D;$d' $_SYSTEMTABLES > $_IPTABLESRULE

    # add default tables
    echo "" >> $_IPTABLESRULE
    cat $_DEFAULTTABLES >> $_IPTABLESRULE

    # add localnet ipset rule
    echo "" >> $_IPTABLESRULE
    if [ -f "$_LOCALNETSETFILE" ]; then
        echo "-A $_FILTERCHAIN -m set --match-set $_LOCALNETSET dst -j RETURN" >> $_IPTABLESRULE
    fi

    # redirect to socket proxy prot
    echo "-A $_FILTERCHAIN -p tcp -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    # redirect pdns tcp connect to local port
    echo "-A PDNSD -d 8.8.8.8/32 -p tcp -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    echo "COMMIT" >> $_IPTABLESRULE
}

vpnGenIptablesRule_backMode(){
    # add system iptables
    iptables-save -t nat > $_SYSTEMTABLES
    # delete last 2 line
    sed 'N;$!P;$!D;$d' $_SYSTEMTABLES > $_IPTABLESRULE

    # add default tables
    echo "" >> $_IPTABLESRULE
    cat $_DEFAULTTABLES >> $_IPTABLESRULE

    # add localnet ipset rule
    echo "" >> $_IPTABLESRULE
    if [ -f "$_LOCALNETSETFILE" ]; then
        echo "-A $_FILTERCHAIN -m set --match-set $_LOCALNETSET dst -j RETURN" >> $_IPTABLESRULE
    fi

    # redirect to socket proxy prot
    echo "" >> $_IPTABLESRULE
    if [ -f "$_CHINASETFILE" ]; then
        echo "-A $_FILTERCHAIN -m set --match-set $_CHINASET dst -p tcp --dport 80 -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    fi

    # redirect pdns tcp connect to local port
    echo "-A PDNSD -d 8.8.8.8/32 -p tcp -j REDIRECT --to-ports $_LOCALPORT" >> $_IPTABLESRULE
    echo "COMMIT" >> $_IPTABLESRULE
}

vpnIptablesAddSpecialRule() {
    local serveraddr=`mci get modou.sshvpn.service_ip_address 2>/dev/null`
    iptables -t nat -I $_FILTERCHAIN -d $serveraddr -j RETURN
}

vpnIptablesAdd(){
    if [ ! -f "$_IPTABLESRULE" ]; then
        return 1
    fi
    iptables-restore $_IPTABLESRULE
    return 0
}

vpnGenRule(){
    vpnGenLocalNetIpSet
    vpnGenChinaIpSet;
    local mode=`mci get modou.sshvpn.mode 2>/dev/null`
    if [ "$mode" == "" -o "$mode" == "智能模式" ]; then
      vpnGenIptablesRule_smartMode
    elif [ "$mode" == "游戏模式" ]; then
      vpnGenIptablesRule_gameMode
    elif [ "$mode" == "全局模式" ]; then
      vpnGenIptablesRule_globalMode
    else
      vpnGenIptablesRule_backMode
    fi
}

vpnRuleStop(){
    vpnIptablesClear;
}

vpnRuleStart(){
    vpnIptablesClear;
    vpnGenRule;
    vpnIpSetAdd;
    vpnIptablesAdd;
    vpnIptablesAddSpecialRule
}

#case "$1" in
#    "stop")
#        stop;
#        if [[ "0" != "$?" ]]; then
#            exit 1;
#        fi
#        exit 0;
#        ;;
#
#    "start")
#        start;
#        if [[ "0" != "$?" ]]; then
#            exit 1;
#        fi
#        exit 0;
#        ;;
#
#    "genrule")
#        genRule;
#        if [[ "0" != "$?" ]]; then
#            exit 1;
#        fi
#        exit 0;
#        ;;
#    *)
#        usage init;
#        exit 1;
#        ;;
#esac
