#!/bin/bash

printf "keybind to search: "

building=0
start=0
expectedline=""
buildquery=""

xmodmap -pke > /tmp/keymap
stty -echo

# COPY AND CLEAR ~/.config/i3/config
cp ~/.config/i3/config /tmp/config
> ~/.config/i3/config
i3-msg reload &> /tmp/log

# 14 IS KEY RELEASED, 13 IS KEY PRESSEDbash xmodmap with no output to terminal
xinput test-xi2 --root 3 | stdbuf -oL awk 'NR > 10' | stdbuf -oL awk '/EVENT/ {type=$4; getline; getline; getline; keycode=$2; fflush()} NR%3==0 {print type,keycode}' | while read -r line; 
    do
        # GET NAME OF KEY PRESSED FROM XMODMAP KEYMAP IN /TMP/KEYMAP
        keychar=$(echo "$line" | awk '{print $2}')
        keyname=$(grep "keycode  $keychar = " /tmp/keymap | awk '{print $4}')

        if [[ $keychar == 133 ]] ; then 
            keyname="$""mod"
        fi

        # BUILD BIND QUERY
        action=$(echo "$line" | awk '{print $1}')
        if [[ "$action" == "(RawKeyPress)" ]] ; then
            # DONT CHANGE EXPECTEDLINE EVERY TIME NEW KEY DOWN
            if [[ $building == 0 ]] ; then    
                building=1
                expectedline="(RawKeyRelease) $keychar"
            fi

            # BUILD 
            if [[ $start == 1 ]] ; then buildquery="$buildquery+$keyname"
            else buildquery="$keyname"
            fi
        fi
        

        # READ FROM /tmp/config copy of ~/.config/i3/config
        if [[ "$line" == "$expectedline" ]] ; then
            echo "$buildquery"

            if grep -q " $buildquery " /tmp/config ; then
                echo "bind taken"
            else
                echo "bind free"
            fi
            pkill -P $$ &> /tmp/log
        fi

        # SINGLE KEY BINDS NOT HAVING + APPENDED
        if [[ $start == 0 ]] ; then 
            start=1 
        fi
    done
stty echo

# CLEAR INPUT BUFFER
perl -e 'use POSIX; tcflush(0, TCIFLUSH);'

# REPOPULATE ~/.config/i3/config
cp /tmp/config ~/.config/i3/config

