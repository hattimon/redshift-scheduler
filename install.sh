#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

log "Installing Redshift Scheduler..."

# Ignore Brave GPG errors
sudo apt update -o APT::Get::AllowUnauthenticated=true 2>&1 | grep -v "NO_PUBKEY" || true

# Install packages
log "Checking packages..."
sudo apt install -y python3 python3-gi gir1.2-gtk-3.0 redshift zenity libnotify-bin 2>&1 | grep -v "already" || true

# Create directories
mkdir -p ~/.local/bin ~/.config/{systemd/user,autostart} ~/.config/redshift-scheduler

# Download files from subdirectory
log "Downloading application files..."
REPO_RAW="https://raw.githubusercontent.com/hattimon/redshift-scheduler/main/redshift-scheduler"

curl -sL "$REPO_RAW/daemon.py" -o ~/.local/bin/redshift-scheduler-daemon || error "daemon.py"
curl -sL "$REPO_RAW/applet.py" -o ~/.local/bin/redshift-scheduler-applet || error "applet.py"

chmod +x ~/.local/bin/redshift-scheduler-*

# Add to PATH
if ! grep -q '\.local/bin' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Default config
cat > ~/.config/redshift-scheduler/config.json << 'EOF'
{
  "enabled": true,
  "schedule": {"start": "21:00", "stop": "08:00"},
  "temps": {"day": 5800, "night": 4800}
}
EOF

# Systemd service
cat > ~/.config/systemd/user/redshift-scheduler.service << 'EOF'
[Unit]
Description=Redshift Scheduler Daemon
After=graphical-session.target

[Service]
Type=simple
ExecStart=%h/.local/bin/redshift-scheduler-daemon
Restart=always
RestartSec=10
Environment=DISPLAY=:0
Environment=XAUTHORITY=%h/.Xauthority

[Install]
WantedBy=default.target
EOF

# Autostart applet
cat > ~/.config/autostart/redshift-scheduler.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Scheduler
Exec=%h/.local/bin/redshift-scheduler-applet
NoDisplay=false
X-XFCE-Autostart-Override=true
EOF

# Enable systemd service
log "Setting up systemd..."
mkdir -p ~/.config/systemd/user
systemctl --user daemon-reload 2>/dev/null || echo "Note: daemon-reload may fail in sandbox, ignore"
systemctl --user enable redshift-scheduler 2>/dev/null || true
systemctl --user restart redshift-scheduler 2>/dev/null || echo "Note: Start via session or: systemctl --user start redshift-scheduler"

log "✅ Installation complete!"
log "📝 Next steps:"
log "  1. Log out and back in (or restart XFCE)"
log "  2. Tray icon appears next to speaker"
log "  3. Check status: systemctl --user status redshift-scheduler"
log "  4. Edit config: nano ~/.config/redshift-scheduler/config.json"

zenity --info --text="✅ Redshift Scheduler installed!\n\n📝 Tray icon appears after session restart\n📊 Status: systemctl --user status redshift-scheduler\n⚙️ Config: ~/.config/redshift-scheduler/config.json" 2>/dev/null || echo "Installation done!"
