#!/bin/bash
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'
log() { echo -e "${GREEN}[*] $1${NC}"; }

zenity --question --text="Remove Redshift Scheduler completely?" 2>/dev/null || read -p "Confirm (y/n): " -n 1 -r; echo

log "Removing..."
systemctl --user stop redshift-scheduler 2>/dev/null || true
systemctl --user disable redshift-scheduler 2>/dev/null || true

rm -rf ~/.local/bin/redshift-scheduler-*
rm -rf ~/.local/share/redshift-scheduler
rm -rf ~/.config/redshift-scheduler
rm -f ~/.config/systemd/user/redshift-scheduler.service
rm -f ~/.config/autostart/redshift-scheduler.desktop

systemctl --user daemon-reload

echo -e "${GREEN}✅ Removed completely!${NC}"
