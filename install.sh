#!/bin/bash
set -e
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

REPO="https://raw.githubusercontent.com/hattimon/redshift-scheduler/main/redshift-scheduler"

log "Installing Redshift Scheduler..."

# Packages
sudo apt update
sudo apt install -y python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 redshift zenity libnotify-bin python3-pip || error "Packages"

pip3 install --user PySimpleGUI 2>/dev/null || pip3 install PySimpleGUI --user

# Download Python files
mkdir -p ~/.local/bin ~/.local/share/redshift-scheduler/icons

curl -sL "$REPO/daemon.py" -o ~/.local/bin/redshift-scheduler-daemon || error "daemon.py"
curl -sL "$REPO/applet.py" -o ~/.local/bin/redshift-scheduler-applet || error "applet.py"
curl -sL "$REPO/gui.py" -o ~/.local/bin/redshift-scheduler-config || error "gui.py"

chmod +x ~/.local/bin/redshift-scheduler-*

# PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Systemd service
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

systemctl --user daemon-reload
systemctl --user enable redshift-scheduler
systemctl --user start redshift-scheduler

log "✅ Installation complete!"
zenity --info --text="Redshift Scheduler ready!\nTray icon next to speaker\nSettings: redshift-scheduler-config"
