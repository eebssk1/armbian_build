#!/bin/sh

if [ "$NM_DISPATCHER_ACTION" = "up" ]; then
if [ "$DEVICE_IFACE" = "lo" ] || [ "$DEVICE_IP_IFACE" = "lo" ]; then
ip route change local 127.0.0.1 dev lo congctl highspeed || true
ip route del local ::1 dev lo metric 0 || true
ip route replace local ::1 dev lo metric 1 congctl highspeed || true
fi
fi
