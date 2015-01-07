#!/bin/sh



CURWDIR=$(cd $(dirname $0) && pwd)
CUSTOMCONF="$CURWDIR/../conf/custom.conf"

[ -f $CURWDIR/../data ] && rm $CURWDIR/../data 
[ ! -d $CURWDIR/../data/ ] && mkdir $CURWDIR/../data/

CUSTOMSETCONF="$CURWDIR/../data/customset.conf"
SETCONF="$CURWDIR/../conf/set.conf"

[ ! -f $CUSTOMSETCONF ] $$ cp $SETCONF $CUSTOMSETCONF

PACKAGEID="com.modouwifi.vpnssh"
DATAJSON="$CURWDIR/../conf/data.json"


CMDHEAD='"cmd":"'
CMDTAIL='",'


SHELLBUTTON1="$CURWDIR/../sbin/ss.sh config"
SHELLBUTTON2="$CURWDIR/../sbin/ss.sh starttp"
SHELLBUTTON22="$CURWDIR/../sbin/ss.sh stop"

CMDBUTTON1=${CMDHEAD}${SHELLBUTTON1}${CMDTAIL};
CMDBUTTON2=${CMDHEAD}${SHELLBUTTON2}${CMDTAIL};
CMDBUTTON22=${CMDHEAD}${SHELLBUTTON22}${CMDTAIL};

