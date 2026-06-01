#!/bin/sh

if [ "$NM_DISPATCHER_ACTION" != "up" ]; then
exit 0
fi

case "$DEVICE_IP_IFACE" in
wl*)
echo "Setting $DEVICE_IP_IFACE ..."
;;
*)
exit 0
;;
esac

#iwconfig $DEVICE_IP_IFACE txpower 27dbm
iwconfig $DEVICE_IP_IFACE retry short 10
iwconfig $DEVICE_IP_IFACE retry long 7
iwconfig $DEVICE_IP_IFACE rts 400
iwconfig $DEVICE_IP_IFACE frag 960
iwconfig $DEVICE_IP_IFACE commit
ip link set dev $DEVICE_IP_IFACE mode default
ip link set dev $DEVICE_IP_IFACE qlen 3200
#tc qdisc replace dev $DEVICE_IP_IFACE root fq_pie noecn

tc qdisc replace dev $DEVICE_IP_IFACE root handle 1: sfq

exit 0
