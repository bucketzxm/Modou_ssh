#!/bin/sh

# get current work path
local _CURDIR=$(cd $(dirname $0) && pwd)

uiCheckProcessStatusByName() {
    local processname="$1"
    local status=`ps -w | grep $processname | wc -l`
    if [ "$status" == "1" ]; then
        echo "dead";
    else
        echo "alive";
    fi
    return 0;
}

# operations for generate a "custom" component configfile
# usage:  genCustomContentByName "ss-redir" "insertinfo" infofile
#         genCustomContentByName "ss-redir" "noinsertinfo"
uiGenCustomContentByName()
{
    [ "$#" != "3" ] && return 1
    local processname="$1"
    local isinsertinfo="$2"
    local infofile="$3"
    local contenthead='"content":"'
    local contenttail='",'
    local contentbody=""
    local linetag="\n"
    isserverstart=`uiCheckProcessStatusByName $processname`
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

# modify the layout and text if necessarry
# uiGenOrUpdateCustomConfig CUSTOMSETCONF TITLE BUTTON1NAME BUTTON1SHELL BUTTON2NAME BUTTON2SHELL \
#                                               BUTTON22NAME BUTTON22SHELL RUNINFOFILE NAME
uiGenOrUpdateCustomConfig2()
{
    # title   :
    # content : dynamic generated (contains setting info)
    # button1 :
    # button2 :
    local CUSTOMCONF=${1}
    local TITLE=${2}
    local CMDHEAD='"cmd":"'
    local CMDTAIL='",'
    local BUTTON1NAME=${3}
    local SHELLBUTTON1=${4}
    local BUTTON2NAME=${5}
    local SHELLBUTTON2="${6}"
    local BUTTON22NAME=${7}
    local SHELLBUTTON22="${8}"
    local CMDBUTTON1=${CMDHEAD}${SHELLBUTTON1}${CMDTAIL};
    local CMDBUTTON2=${CMDHEAD}${SHELLBUTTON2}${CMDTAIL};
    local CMDBUTTON22=${CMDHEAD}${SHELLBUTTON22}${CMDTAIL};
    local RUNINFOFILE=${9}
    local NAME=${10}
    echo '
    {
        "title": ' > $CUSTOMCONF
    echo "\"$TITLE\"," >> $CUSTOMCONF
    local content=`uiGenCustomContentByName $NAME "insertinfo" $RUNINFOFILE`
    echo $content >> $CUSTOMCONF
    echo '
        "button1": {
    ' >> $CUSTOMCONF
    echo $CMDBUTTON1 >> $CUSTOMCONF
    echo '
            "txt":' >> $CUSTOMCONF
    echo "\"$BUTTON1NAME\"," >> $CUSTOMCONF
    echo '
            "code": {"0": "正在显示", "-1": "执行失败"}
            },
        "button2": {
    ' >>$CUSTOMCONF
    local isserverstart=`uiCheckProcessStatusByName $NAME`
    if [ "$isserverstart" == "alive" ]; then
        echo $CMDBUTTON22 >> $CUSTOMCONF
        echo '
            "txt": ' >> $CUSTOMCONF
        echo "\"$BUTTON22NAME\"," >> $CUSTOMCONF
    else
        echo $CMDBUTTON2 >> $CUSTOMCONF
        echo '
            "txt": ' >> $CUSTOMCONF
        echo "\"$BUTTON2NAME\"," >> $CUSTOMCONF
    fi
    echo '
            "code": {"0": "start success", "-1": "执行失败"}
            }
    }
    ' >> $CUSTOMCONF
    return 0;
}

# uiGenOrUpdateCustomConfig3 CUSTOMSETCONF TITLE BUTTON1NAME BUTTON1SHELL
#                                               BUTTON2NAME BUTTON2SHELL \
#                                               BUTTON22NAME BUTTON22SHELL \
#                                               BUTTON3NAME BUTTON3SHELL \
#                                               BUTTON33NAME BUTTON33SHELL \
#                                               RUNINFOFILE NAME
uiGenOrUpdateCustomConfig3()
{
    # title   :
    # content : dynamic generated (contains setting info)
    # button1 :
    # button2 :
    local CUSTOMCONF=${1}
    local TITLE=${2}
    local CMDHEAD='"cmd":"'
    local CMDTAIL='",'
    local BUTTON1NAME=${3}
    local SHELLBUTTON1=${4}
    local BUTTON2NAME=${5}
    local SHELLBUTTON2="${6}"
    local BUTTON22NAME=${7}
    local SHELLBUTTON22="${8}"
    local BUTTON3NAME=${9}
    local SHELLBUTTON3="${10}"
    local BUTTON33NAME=${11}
    local SHELLBUTTON33="${12}"
    local CMDBUTTON1=${CMDHEAD}${SHELLBUTTON1}${CMDTAIL};
    local CMDBUTTON2=${CMDHEAD}${SHELLBUTTON2}${CMDTAIL};
    local CMDBUTTON22=${CMDHEAD}${SHELLBUTTON22}${CMDTAIL};
    local CMDBUTTON3=${CMDHEAD}${SHELLBUTTON3}${CMDTAIL};
    local CMDBUTTON33=${CMDHEAD}${SHELLBUTTON33}${CMDTAIL};
    local RUNINFOFILE=${13}
    local NAME=${14}
    local ISBAND=${15}
    echo '
    {
        "title": ' > $CUSTOMCONF
    echo "\"$TITLE\"," >> $CUSTOMCONF
    local content=`uiGenCustomContentByName $NAME "insertinfo" $RUNINFOFILE`
    echo $content >> $CUSTOMCONF
    echo '
        "button1": {
    ' >> $CUSTOMCONF
    echo $CMDBUTTON1 >> $CUSTOMCONF
    echo '
            "txt":' >> $CUSTOMCONF
    echo "\"$BUTTON1NAME\"," >> $CUSTOMCONF
    echo '
            "code": {"0": "正在显示", "-1": "执行失败"}
            },
        "button2": {
    ' >>$CUSTOMCONF
    local isserverstart=`uiCheckProcessStatusByName $NAME`
    if [ "$isserverstart" == "dead" ]; then
        echo $CMDBUTTON2 >> $CUSTOMCONF
        echo '
            "txt":' >> $CUSTOMCONF
        echo "\"$BUTTON2NAME\"," >> $CUSTOMCONF
    else
        if [ "$ISBAND" == "binded" ]; then
            echo $CMDBUTTON22 >> $CUSTOMCONF
            echo '
            "txt":' >> $CUSTOMCONF
            echo "\"$BUTTON22NAME\"," >> $CUSTOMCONF
        else
            echo $CMDBUTTON2 >> $CUSTOMCONF
            echo '
            "txt":' >> $CUSTOMCONF
            echo "\"$BUTTON2NAME\"," >> $CUSTOMCONF
        fi
    fi
    echo '
            "code": {"0": "start success", "-1": "执行失败"}
            },
        "button3": {
    ' >> $CUSTOMCONF
    local isserverstart=`uiCheckProcessStatusByName $NAME`
    if [ "$isserverstart" == "alive" ]; then
        echo $CMDBUTTON33 >> $CUSTOMCONF
        echo '
            "txt": ' >> $CUSTOMCONF
        echo "\"$BUTTON33NAME\"," >> $CUSTOMCONF
    else
        echo $CMDBUTTON3 >> $CUSTOMCONF
        echo '
            "txt": ' >> $CUSTOMCONF
        echo "\"$BUTTON3NAME\"," >> $CUSTOMCONF
    fi
    echo '
            "code": {"0": "start success", "-1": "执行失败"}
            }
    }
    ' >> $CUSTOMCONF
    return 0;
}

