#!/bin/bash

# $1 = master/backup
# $2 = notification_file

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "Usage: $0 disired_state notification_output_file"
    exit 255
fi

# set to 'true' if the host is supposed to be in MASTER state
# or set to 'false' if the host is supposed to be in BACKUP state
# nrpe cannot receive external variables UNLESS is forced in config
if [ $1 == "master" ]; then
        MASTER='true'
else
        MASTER='false'
fi

OK=0            # - Service is OK.
WARNING=1       # - Service has a WARNING.
CRITICAL=2      # - Service is in a CRITICAL status.
UNKNOWN=3       # - Service status is UNKNOWN.

# checking if there are alive keepalived processes so we can trust the content of the notify 'state' file
KEEPALIVENUM=$(ps aux | grep -v grep | grep keepalived -c)

if [ $KEEPALIVENUM -gt 0 ]; then

        KEEPALIVESTATE=$(cat $2)

        if [ "$MASTER" == "true" ]; then

                if [[ $KEEPALIVESTATE == *"MASTER"* ]];then
                        echo OK: $KEEPALIVESTATE
                        exit $OK
                fi

                if [[ $KEEPALIVESTATE == *"BACKUP"* ]];then
                        echo WARNING: $KEEPALIVESTATE
                        exit $WARNING
                fi

        else

                if [[ $KEEPALIVESTATE == *"BACKUP"* ]];then
                        echo OK: $KEEPALIVESTATE
                        exit $OK
                fi

                if [[ $KEEPALIVESTATE == *"MASTER"* ]];then
                        echo WARNING: $KEEPALIVESTATE
                        exit $WARNING
                fi

          fi
fi

echo "Keepalived is in UNKNOWN state"
exit $UNKNOWN
