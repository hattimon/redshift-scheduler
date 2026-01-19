#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/hattimon/redshift-scheduler/main/redshift-scheduler"

log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

log "Installing Redshift Scheduler..."

# Internet check
ping -c 1 archive.ubuntu.com &>/dev/null || error "No internet."

# Packages (NO jq!)
sudo apt update
sudo apt install -y python3 python3-gi python3-gi-cairo gir1.2-gtk-3.0 \
  redshift zenity libnotify-bin pipx || error "Packages failed."

# PySimpleGUI via pipx (fixes externally-managed)
pipx ensurepath
pipx install PySimpleGUI --include-deps >/dev/null 2>&1 || true

# Directories
mkdir -p ~/.local/bin ~/.config/{systemd/user,autostart} ~/.config/redshift-scheduler

# Download Python files from GitHub raw
log "Downloading application..."
curl -sL "$REPO_RAW/daemon.py" -o ~/.local/bin/redshift-scheduler-daemon || error "daemon.py"
curl -sL "$REPO_RAW/applet.py" -o ~/.local/bin/redshift-scheduler-applet || error "applet.py"
curl -sL "$REPO_RAW/gui.py" -o ~/.local/bin/redshift-scheduler-config || error "gui.py"

chmod +x ~/.local/bin/redshift-scheduler-*

# PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

# Systemd service (FIXED display)
cat > ~/.config/systemd/user/redshift-scheduler.service << 'EOF'
[Unit]
Description=Redshift Scheduler
After=graphical-session.target

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

# XFCE autostart applet
cat > ~/.config/autostart/redshift-scheduler.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Scheduler Applet
Exec=%h/.local/bin/redshift-scheduler-applet
NoDisplay=false
EOF

# Enable services
systemctl --user daemon-reload
systemctl --user enable --now redshift-scheduler

log "✅ Installation COMPLETE!"
log "🖥️ Tray icon: next to speaker (restart XFCE if needed)"
log "⚙️ Settings: redshift-scheduler-config"
log "📊 Status: systemctl --user status redshift-scheduler"

zenity --info --text="✅ Redshift Scheduler installed!\n\nTray: speaker area\nConfig: redshift-scheduler-config" 2>/dev/null || true
