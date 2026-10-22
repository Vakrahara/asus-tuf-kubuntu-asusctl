#!/usr/bin/env bash
# ==============================================================================
# ASUS TUF Gaming F15 - ZRAM Rollback Script
# Restores original factory memory & swap configuration
# ==============================================================================
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

echo "Stopping ZRAM..."
swapoff /dev/zram0 2>/dev/null || true
systemctl stop /dev/zram0 2>/dev/null || true
systemctl stop systemd-zram-setup@zram0.service 2>/dev/null || true

echo "Removing configuration files..."
rm -f /etc/systemd/zram-generator.conf
rm -f /etc/sysctl.d/99-zram-tuning.conf

echo "Restoring /etc/fstab..."
if [ -f /etc/fstab.bak ]; then
    cp /etc/fstab.bak /etc/fstab
else
    sed -i 's/,pri=10//g' /etc/fstab
fi

echo "Removing systemd-zram-generator..."
apt-get purge -y systemd-zram-generator || true

sysctl -w vm.swappiness=60
sysctl -w vm.page-cluster=3

systemctl daemon-reload

echo "Restoring default swap..."
swapoff -a || true
swapon -a || true

echo "System restored to default memory configuration!"
swapon --show
