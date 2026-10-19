#!/usr/bin/env bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${RED}================================================================${NC}"
echo -e "${RED}  ASUS TUF FX506 asusctl Clean Uninstaller                     ${NC}"
echo -e "${RED}  Restoring system to default factory Kubuntu state             ${NC}"
echo -e "${RED}================================================================${NC}"

# Check for root/sudo
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do NOT run this script directly as root or with sudo.${NC}"
    echo "Run it as your normal user. It will prompt for sudo when required."
    exit 1
fi

echo -e "\n${BLUE}[1/4] Stopping asusd services...${NC}"
sudo systemctl disable --now asusd.service 2>/dev/null || true
systemctl --user disable --now asusd-user.service 2>/dev/null || true
rm -f ~/.config/systemd/user/asusd-user.service 2>/dev/null || true
systemctl --user daemon-reload 2>/dev/null || true

echo -e "\n${BLUE}[2/4] Restoring original power & thermal daemons...${NC}"
sudo systemctl unmask power-profiles-daemon thermald systemd-backlight@leds:asus::kbd_backlight.service 2>/dev/null || true
sudo systemctl enable --now power-profiles-daemon 2>/dev/null || true
sudo systemctl enable --now thermald 2>/dev/null || true
sudo systemctl restart systemd-backlight@leds:asus::kbd_backlight.service 2>/dev/null || true

echo -e "\n${BLUE}[3/4] Removing installed binaries and system files...${NC}"
sudo rm -f /usr/bin/asusctl /usr/bin/asusd /usr/bin/asusd-user /usr/bin/rog-control-center
sudo rm -f /usr/lib/systemd/system/asusd.service /usr/lib/systemd/system/asus-shutdown.service
sudo rm -f /usr/lib/systemd/user/asusd-user.service
sudo rm -f /usr/lib/udev/rules.d/99-asusd.rules
sudo rm -f /usr/share/dbus-1/system.d/asusd.conf /usr/share/dbus-1/system.d/org.asuslinux.conf
sudo rm -f /usr/share/applications/org.opengamingcollective.rog-control-center.desktop
sudo rm -rf /etc/asusd /usr/share/asusd

echo -e "\n${BLUE}[4/4] Resetting battery charge threshold to 100%...${NC}"
for bat in /sys/class/power_supply/BAT*; do
    if [ -f "$bat/charge_control_end_threshold" ]; then
        echo 100 | sudo tee "$bat/charge_control_end_threshold" >/dev/null || true
    fi
done

sudo systemctl daemon-reload

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}  UNINSTALLATION COMPLETE! System is restored to default state. ${NC}"
echo -e "${GREEN}================================================================${NC}"
