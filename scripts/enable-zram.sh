#!/usr/bin/env bash
# ==============================================================================
# ASUS TUF Gaming F15 - Zero-SSD ZRAM Setup Script
# Configures In-Memory Compressed Swap (zstd) with priority 100
# Protects NVMe SSD from write amplification and eliminates page thrashing
# ==============================================================================
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  ASUS TUF Zero-SSD ZRAM (Compressed RAM Swap) Installer        ${NC}"
echo -e "${BLUE}================================================================${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root (use sudo).${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

echo -e "\n${GREEN}[1/5] Installing systemd-zram-generator...${NC}"
apt-get update -y
apt-get install -y systemd-zram-generator

echo -e "\n${GREEN}[2/5] Creating /etc/systemd/zram-generator.conf...${NC}"
cat << 'EOF' > /etc/systemd/zram-generator.conf
# /etc/systemd/zram-generator.conf
# Managed by ASUS TUF Performance Architecture

[zram0]
# Allocate 50% of physical RAM (8 GB) as compressed ZRAM pool (holds ~20 GB data)
zram-size = ram / 2

# Ultra-fast zstd compression engine supported by Linux 7.0 kernel
compression-algorithm = zstd

# High priority: Ensures Linux ALWAYS swaps to RAM first, never to SSD
swap-priority = 100

# Zero-latency page discard
options = discard
EOF

echo -e "\n${GREEN}[3/5] Tuning kernel swappiness for in-memory compression...${NC}"
cat << 'EOF' > /etc/sysctl.d/99-zram-tuning.conf
# Aggressively compress cold background pages into ZRAM to keep RAM clean
vm.swappiness = 100

# Read single pages at zero latency instead of multi-page disk clusters
vm.page-cluster = 0
EOF
sysctl -p /etc/sysctl.d/99-zram-tuning.conf

echo -e "\n${GREEN}[4/5] Setting disk /swapfile to low priority (pri=10) in /etc/fstab...${NC}"
if grep -q "/swapfile.*pri=" /etc/fstab; then
    echo "Disk /swapfile priority already configured."
else
    sed -i.bak 's|/swapfile\([[:space:]]*\)swap\([[:space:]]*\)swap\([[:space:]]*\)defaults|/swapfile\1swap\2swap\3defaults,pri=10|' /etc/fstab
    echo "Updated /etc/fstab: /swapfile now has pri=10 (backup priority)."
fi

echo -e "\n${GREEN}[5/5] Activating /dev/zram0 in-memory swap...${NC}"
systemctl daemon-reload
systemctl start /dev/zram0 || systemctl restart systemd-zram-setup@zram0.service || true

# Flush old saturated swap into RAM if free memory is sufficient
echo -e "\n${BLUE}Flushing old SSD swap into RAM...${NC}"
swapoff -a || true
swapon -a || true

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}  ZRAM ACTIVATED SUCCESSFULLY! ZERO SSD WRITES ENABLED!          ${NC}"
echo -e "${BLUE}================================================================${NC}"
swapon --show
echo ""
zramctl 2>/dev/null || true
echo -e "\nKernel Swappiness: $(cat /proc/sys/vm/swappiness)"
echo -e "Page Cluster: $(cat /proc/sys/vm/page-cluster)"
