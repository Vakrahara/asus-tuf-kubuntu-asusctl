#!/usr/bin/env bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  ASUS TUF FX506 asusctl & ROG Control Center Installer        ${NC}"
echo -e "${BLUE}  Tested on: Kubuntu / Ubuntu with KDE Plasma                   ${NC}"
echo -e "${BLUE}================================================================${NC}"

# Check for root/sudo
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do NOT run this script directly as root or with sudo.${NC}"
    echo "Run it as your normal user. It will prompt for sudo when required."
    exit 1
fi

echo -e "\n${GREEN}[1/6] Installing build toolchain and libraries...${NC}"
sudo apt update
sudo apt install -y \
    build-essential git cmake pkg-config clang \
    libclang-dev libudev-dev libssl-dev libfontconfig1-dev \
    libinput-dev libseat-dev libxkbcommon-dev libgbm-dev libpci-dev gettext curl

if ! command -v cargo &>/dev/null; then
    echo -e "${BLUE}Installing Rust via rustup...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

echo -e "\n${GREEN}[2/6] Neutralizing conflicting system daemons...${NC}"
sudo systemctl stop power-profiles-daemon thermald 2>/dev/null || true
sudo systemctl mask power-profiles-daemon thermald systemd-backlight@leds:asus::kbd_backlight.service 2>/dev/null || true
sudo apt purge -y openrgb thinkfan 2>/dev/null || true

echo -e "\n${GREEN}[3/6] Setting up systemd sandbox directory...${NC}"
sudo mkdir -p /etc/asusd
sudo chmod 755 /etc/asusd

echo -e "\n${GREEN}[4/6] Compiling asusctl and rog-control-center from upstream...${NC}"
TEMP_BUILD_DIR=$(mktemp -d /tmp/asusctl-build.XXXXXX)
git clone --depth 1 https://github.com/OpenGamingCollective/asusctl.git "$TEMP_BUILD_DIR"
cd "$TEMP_BUILD_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/patches/rog-control-center-ui-enhancements.patch" ]; then
    echo -e "${BLUE}Applying UI enhancements (1-click Battery Presets & Animated Neon ROG Logo)...${NC}"
    git apply "$SCRIPT_DIR/patches/rog-control-center-ui-enhancements.patch" || true
elif [ -f "$SCRIPT_DIR/patches/battery-preset-buttons.patch" ]; then
    git apply "$SCRIPT_DIR/patches/battery-preset-buttons.patch" || true
fi

make
sudo make install
rm -rf "$TEMP_BUILD_DIR"

echo -e "\n${GREEN}[5/6] Starting asusd hardware daemon...${NC}"
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo systemctl enable --now asusd.service

# Install prime-run NVIDIA offload utility
if [ -f "$SCRIPT_DIR/bin/prime-run" ]; then
    echo -e "${BLUE}Installing NVIDIA prime-run offload helper...${NC}"
    sudo install -D -m 0755 "$SCRIPT_DIR/bin/prime-run" /usr/local/bin/prime-run
    mkdir -p "$HOME/.local/bin"
    cp "$SCRIPT_DIR/bin/prime-run" "$HOME/.local/bin/prime-run"
    chmod +x "$HOME/.local/bin/prime-run"
fi

# Remove/disable buggy asusd-user on TUF (prevents AniMe Matrix crashes)
systemctl --user stop asusd-user.service 2>/dev/null || true
systemctl --user disable asusd-user.service 2>/dev/null || true
rm -f ~/.config/systemd/user/asusd-user.service 2>/dev/null || true
systemctl --user daemon-reload 2>/dev/null || true

echo -e "\n${GREEN}[6/6] Applying default hardware parameters...${NC}"
# Set 60% battery threshold
asusctl battery limit 60 || echo "Note: Run 'asusctl battery limit 60' after reboot if needed."
asusctl profile set Balanced || echo "Note: Run 'asusctl profile set Balanced' after reboot."

echo -e "\n${BLUE}================================================================${NC}"
echo -e "${GREEN}  INSTALLATION SUCCESSFUL!                                      ${NC}"
echo -e "${BLUE}================================================================${NC}"
asusctl info
echo -e "\nBattery Threshold: $(cat /sys/class/power_supply/BAT*/charge_control_end_threshold 2>/dev/null || echo '60')%"
echo -e "Active Profile: $(asusctl profile get 2>/dev/null || echo 'Balanced')"
echo -e "\nYou can now launch 'ROG Control Center' from your Application Menu!"
