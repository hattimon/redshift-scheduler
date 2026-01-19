#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# GitHub raw repository base URL
REPO_RAW="https://raw.githubusercontent.com/hattimon/redshift-scheduler/main/redshift-scheduler"

# Functions
log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

log "Installing Redshift Scheduler..."

# 🔍 Check internet
if ! ping -c 1 archive.ubuntu.com &>/dev/null; then
  error "No internet connection."
fi

# 📦 Install packages
log "Installing required packages..."
sudo apt update
sudo apt install -y python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
  redshift zenity libnotify-bin python3-pip || error "Failed to install packages."

# 🐍 Python dependencies
pip3 install --user PySimpleGUI >/dev/null 2>&1 || pip3 install PySimpleGUI --user || true

# 📁 Create directories
mkdir -p ~/.local/bin ~/.local/share/redshift-scheduler/icons \
  ~/.config/redshift-scheduler ~/.config/systemd/user ~/.config/autostart

# 📥 Download Python files directly from GitHub raw
log "Downloading application files..."
curl -sL "$REPO_RAW/daemon.py" -o ~/.local/bin/redshift-scheduler-daemon || error "Failed to download daemon.py"
curl -sL "$REPO_RAW/applet.py" -o ~/.local/bin/redshift-scheduler-applet || error "Failed to download applet.py"
curl -sL "$REPO_RAW/gui.py" -o ~/.local/bin/redshift-scheduler-config || error "Failed to download gui.py"
curl -sL "$REPO_RAW/__init__.py" -o ~/.local/bin/redshift-scheduler/__init__.py 2>/dev/null || true

chmod +x ~/.local/bin/redshift-scheduler-*

# 🌐 Add to PATH permanently
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# 🔧 Systemd user service
cat > ~/.config/systemd/user/redshift-scheduler.service << 'EOF'
[Unit]
Description=Redshift Scheduler Daemon
After=network.target graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/redshift-scheduler-daemon
Restart=always
RestartSec=5
Environment=DISPLAY=:0
Environment=XDG_RUNTIME_DIR=%h/.xdg

[Install]
WantedBy=default.target
EOF

# 🔧 XFCE autostart (tray applet)
cat > ~/.config/autostart/redshift-scheduler.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Scheduler Applet
Exec=%h/.local/bin/redshift-scheduler-applet
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Categories=Utility;
Comment=Redshift night light scheduler
EOF

# 🚀 Enable and start services
systemctl --user daemon-reload
systemctl --user enable redshift-scheduler
systemctl --user start redshift-scheduler

log "✅ Installation completed successfully!"
log "🌟 Features:"
log "• Daemon running: systemctl --user status redshift-scheduler"
log "• Tray applet: next to speaker (auto-start)"
log "• Settings GUI: redshift-scheduler-config"
log "• Reload: source ~/.bashrc"

# Graficzny success
zenity --info \
  --title="Redshift Scheduler" \
  --text="✅ Installation complete!\n\nTray icon appears next to speaker\nSettings: redshift-scheduler-config\nStatus: systemctl --user status redshift-scheduler" \
  2>/dev/null || echo "Installation done! Check tray icon."
