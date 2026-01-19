#!/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/hattimon/redshift-scheduler/main/redshift-scheduler"

log() { echo -e "${GREEN}[*] $1${NC}"; }
error() { echo -e "${RED}[✗] $1${NC}"; exit 1; }

log "Installing Redshift Scheduler..."

sudo apt update -o APT::Get::AllowUnauthenticated=true 2>&1 | grep -v "NO_PUBKEY" || true
sudo apt install -y python3 python3-gi gir1.2-gtk-3.0 redshift zenity libnotify-bin 2>&1 | grep -v "already" || true

mkdir -p ~/.local/bin ~/.config/{autostart} ~/.config/redshift-scheduler

log "Downloading application files..."
curl -sL "$REPO_RAW/daemon.py" -o ~/.local/bin/redshift-scheduler-daemon || error "daemon.py"
curl -sL "$REPO_RAW/applet.py" -o ~/.local/bin/redshift-scheduler-applet || error "applet.py"

chmod +x ~/.local/bin/redshift-scheduler-*

if ! grep -q '\.local/bin' ~/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

cat > ~/.config/redshift-scheduler/config.json << 'EOF'
{
  "enabled": true,
  "schedule": {"start": "21:00", "stop": "08:00"},
  "temps": {"day": 5800, "night": 4800}
}
EOF

cat > ~/.config/autostart/redshift-scheduler.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Redshift Scheduler
Exec=%h/.local/bin/redshift-scheduler-applet
NoDisplay=false
X-XFCE-Autostart-Override=true
Hidden=false
EOF

log "✅ Installation complete!"
log "📝 Next steps:"
log "  1. Restart XFCE or log out/in"
log "  2. Tray icon appears in panel (🌙)"
log "  3. Manual start: ~/.local/bin/redshift-scheduler-applet &"
log "  4. Config: nano ~/.config/redshift-scheduler/config.json"

zenity --info --text="✅ Redshift Scheduler installed!\n\n🌙 Tray applet starts with XFCE\n⚙️ Config: ~/.config/redshift-scheduler/config.json\n📝 Manual: ~/.local/bin/redshift-scheduler-applet &" 2>/dev/null || true
