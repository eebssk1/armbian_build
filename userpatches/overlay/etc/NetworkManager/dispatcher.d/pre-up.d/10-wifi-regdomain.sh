#!/bin/sh

INTERFACE="$1"
ACTION="$2"

#The hidden watter without relay on modded regdb
if [ "$ACTION" = "pre-up" ] && [ -d "/sys/class/net/$INTERFACE/wireless" ]; then
    /usr/sbin/iw reg set CR
fi

exit 0