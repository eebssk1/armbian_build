#!/bin/sh

sysctl vm.swappiness=66
sysctl vm.vfs_cache_pressure=70
sysctl vm.page-cluster=1
sysctl vm.dirty_background_ratio=15
sysctl vm.dirty_ratio=15
sysctl kernel.io_delay_type=2
sysctl net.ipv4.tcp_congestion_control=bbr

apt-get install -y jitterentropy-rngd
mount -o remount,rw /
mount -o remount,rw /sys
mount -o remount,rw /sys/kernel/debug
chmod 0755 /sys /sys/* /sys/module  /sys/module/* /sys/kernel/debug
chmod 0755 /sys/module/zswap/parameters
chmod 0644 /sys/module/zswap/parameters/*
echo N > /sys/module/zswap/parameters/enabled
echo lz4 > /sys/module/zswap/parameters/compressor
echo zsmalloc > /sys/module/zswap/parameters/zpool
echo Y > /sys/module/zswap/parameters/enabled
echo 4100000 > /sys/kernel/debug/sched/latency_ns
echo 620000 > /sys/kernel/debug/sched/min_granularity_ns
echo 360000 > /sys/kernel/debug/sched/wakeup_granularity_ns
echo 400000 > /sys/kernel/debug/sched/migration_cost_ns
rm -rf /usr/local/lib/android
rm -rf /usr/share/dotnet
rm -rf /opt/ghc
rm -rf /usr/local/.ghcup
rm -rf "$AGENT_TOOLSDIRECTORY"
cat <<EOF |tee /etc/apt/preferences.d/nosnap.pref
Package: snapd
Pin: release a=*
Pin-Priority: -10

Package: snap
Pin: release a=*
Pin-Priority: -10
EOF
systemctl stop --force snapd
systemctl disable --now snapd.socket
rm -rf /var/cache/snapd /var/lib/snapd /snap ~/snap
dpkg --purge firefox xul-ext-ubufox
apt-get purge -y '^aspnetcore-.*' '^dotnet-.*' '^llvm-.*' 'php.*' '^mongodb-.*' '^mysql-.*' '^ghc-.*' azure-cli google-chrome-stable firefox powershell hhvm mono-devel libgl1-mesa-dri google-cloud-sdk google-cloud-cli '^firefox.*' snapd snap --autoremove --purge
apt-get clean
docker image prune --all --force
exit 0
