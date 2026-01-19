#!/bin/bash
set -e

GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

# Graficzny progress
show_progress() {
  zenity --progress --no-cancel --auto-close --text="Installing Redshift Scheduler..." 2>/dev/null || true
}

log "Installing Redshift Scheduler..."

# Packages
sudo apt update
sudo apt install -y python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 redshift zenity libnotify-bin python3-pil || error "Packages failed"

# Python GUI lib
pip3 install --user pysimplegui 2>/dev/null || true

# Create structure
mkdir -p ~/.config/redshift-scheduler
mkdir -p ~/.local/share/redshift-scheduler/icons
mkdir -p ~/.local/bin

# Copy files (z repo)
cp redshift-scheduler/daemon.py ~/.local/bin/redshift-scheduler-daemon
cp redshift-scheduler/applet.py ~/.local/bin/redshift-scheduler-applet
cp redshift-scheduler/gui.py ~/.local/bin/redshift-scheduler-config
chmod +x ~/.local/bin/redshift-scheduler-*

# Icons (placeholder SVG)
cp data/icons/*.svg ~/.local/share/redshift-scheduler/icons/ 2>/dev/null || true

# Systemd service (user)
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/redshift-scheduler.service << 'EOF'
[Unit]
Description=Redshift Scheduler
After=network.target

[Service]
Type=simple
ExecStart=%h/.local/bin/redshift-scheduler-daemon
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
EOF

# XFCE autostart
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/redshift-scheduler.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Scheduler
Exec=%h/.local/bin/redshift-scheduler-applet
NoDisplay=false
Terminal=false
Categories=Utility;
EOF

# Enable systemd service
systemctl --user daemon-reload
systemctl --user enable redshift-scheduler
systemctl --user start redshift-scheduler

log "✅ Installation complete!"
zenity --info --text="Redshift Scheduler installed!\n\n✅ Daemon running\n✅ Tray applet active\n✅ Settings: redshift-scheduler-config" 2>/dev/null || echo "Setup done!"
