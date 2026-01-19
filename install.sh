#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/hattimon/redshift-scheduler/main/redshift-scheduler"

log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

log "Installing Redshift Scheduler (No Python GUI deps)..."

# Packages (NO pipx/PySimpleGUI!)
sudo apt update
sudo apt install -y python3 python3-gi gir1.2-gtk-3.0 redshift zenity libnotify-bin || error "Packages"

# Directories
mkdir -p ~/.local/bin ~/.config/{systemd/user,autostart} ~/.config/redshift-scheduler

# Download Python files (Python3-gi dla applet)
log "Downloading core files..."
curl -sL "$REPO_RAW/daemon.py" -o ~/.local/bin/redshift-scheduler-daemon || error "daemon"
curl -sL "$REPO_RAW/applet.py" -o ~/.local/bin/redshift-scheduler-applet || error "applet"

chmod +x ~/.local/bin/redshift-scheduler-*

# PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Default config (bez PySimpleGUI)
cat > ~/.config/redshift-scheduler/config.json << EOF
{
  "enabled": true,
  "schedule": {"start": "21:00", "stop": "08:00"},
  "temps": {"day": 5800, "night": 4800}
}
EOF

# Systemd service (XFCE-ready)
cat > ~/.config/systemd/user/redshift-scheduler.service << 'EOF'
[Unit]
Description=Redshift Scheduler
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/redshift-scheduler-daemon
Restart=always
RestartSec=10
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

# XFCE autostart (tray applet)
cat > ~/.config/autostart/redshift-scheduler.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Scheduler
Exec=%h/.local/bin/redshift-scheduler-applet
NoDisplay=false
EOF

# Enable services
systemctl --user daemon-reload
systemctl --user enable redshift-scheduler
systemctl --user restart redshift-scheduler

log "✅ Installation COMPLETE! (lightweight)"
log "🖥️ Tray icon: restart XFCE or log out/in"
log "📊 Status: systemctl --user status redshift-scheduler"
log "⚙️ Config: nano ~/.config/redshift-scheduler/config.json"
log "🌙 Default: 21:00-08:00 night mode"

zenity --info --text="✅ Redshift Scheduler ready!\n\nTray icon after restart\nStatus: systemctl --user status redshift-scheduler\nConfig: ~/.config/redshift-scheduler/config.json" 2>/dev/null || true
