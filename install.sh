#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}🚀 Redshift Scheduler - Complete Installation${NC}\n"

# ============================================
# 1. CREATE DIRECTORIES
# ============================================
echo -e "${GREEN}📁 Creating directories...${NC}"
mkdir -p ~/.local/bin
mkdir -p ~/.config/redshift-scheduler
mkdir -p ~/.config/systemd/user
chmod 700 ~/.config/systemd/user

# ============================================
# 2. INSTALL DAEMON
# ============================================
echo -e "${GREEN}📦 Installing daemon...${NC}"
cat > ~/.local/bin/redshift-scheduler-daemon << 'DAEMON_SCRIPT'
#!/usr/bin/env python3
"""Redshift Scheduler Daemon - Controls redshift based on schedule"""
import json
import os
import time
import subprocess
import sys
from datetime import datetime

CONFIG_FILE = os.path.expanduser("~/.config/redshift-scheduler/config.json")

def load_config():
    """Load configuration from JSON file"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading config: {e}", file=sys.stderr)
        return {"enabled": True, "start_hour": 21, "end_hour": 8, "temperature": 4500}

def is_enabled():
    """Check if redshift scheduler is enabled"""
    config = load_config()
    return config.get("enabled", True)

def get_time_range():
    """Get start and end hours from config"""
    config = load_config()
    return config.get("start_hour", 21), config.get("end_hour", 8)

def get_temperature():
    """Get temperature setting from config"""
    config = load_config()
    return config.get("temperature", 4500)

def should_enable_redshift():
    """Determine if redshift should be enabled based on current time"""
    start_h, end_h = get_time_range()
    now = datetime.now()
    current_h = now.hour
    
    # Handle time range crossing midnight (e.g., 21:00 - 08:00)
    if start_h > end_h:
        return current_h >= start_h or current_h < end_h
    else:
        return start_h <= current_h < end_h

def set_redshift_state(enable):
    """Enable or disable redshift"""
    try:
        if enable:
            temp = get_temperature()
            result = subprocess.run(
                ["redshift", "-O", str(temp)],
                capture_output=True,
                timeout=5
            )
            if result.returncode != 0:
                print(f"Redshift ON failed: {result.stderr.decode()}", file=sys.stderr)
            else:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Redshift ON ({temp}K)")
        else:
            result = subprocess.run(
                ["redshift", "-x"],
                capture_output=True,
                timeout=5
            )
            if result.returncode != 0:
                print(f"Redshift OFF failed: {result.stderr.decode()}", file=sys.stderr)
            else:
                print(f"[{datetime.now().strftime('%H:%M:%S')}] Redshift OFF")
    except FileNotFoundError:
        print("Error: redshift not found. Install with: sudo apt install redshift", file=sys.stderr)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)

def main():
    """Main daemon loop"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Redshift Scheduler Daemon started")
    last_state = None
    
    while True:
        try:
            if is_enabled():
                current_state = should_enable_redshift()
                if current_state != last_state:
                    set_redshift_state(current_state)
                    last_state = current_state
            else:
                # Disable redshift if scheduler is turned off
                if last_state is not False:
                    subprocess.run(["redshift", "-x"], capture_output=True, timeout=5)
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Scheduler disabled, redshift OFF")
                    last_state = False
            
            time.sleep(60)
        except KeyboardInterrupt:
            print("\nShutdown requested")
            break
        except Exception as e:
            print(f"Daemon error: {e}", file=sys.stderr)
            time.sleep(60)

if __name__ == "__main__":
    main()
DAEMON_SCRIPT

chmod +x ~/.local/bin/redshift-scheduler-daemon

# ============================================
# 3. INSTALL APPLET (GUI)
# ============================================
echo -e "${GREEN}📦 Installing applet (GUI)...${NC}"
cat > ~/.local/bin/redshift-scheduler-applet << 'APPLET_SCRIPT'
#!/usr/bin/env python3
"""Redshift Scheduler Applet - System tray GUI toggle"""
import tkinter as tk
from tkinter import messagebox
import json
import os
import subprocess
import sys

CONFIG_FILE = os.path.expanduser("~/.config/redshift-scheduler/config.json")

def load_config():
    """Load configuration from JSON file"""
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except Exception as e:
        messagebox.showerror("Error", f"Cannot load config: {e}")
        sys.exit(1)

def save_config(config):
    """Save configuration to JSON file"""
    try:
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)
    except Exception as e:
        messagebox.showerror("Error", f"Cannot save config: {e}")

def toggle_enabled():
    """Toggle scheduler enabled/disabled"""
    config = load_config()
    config["enabled"] = not config.get("enabled", True)
    save_config(config)
    update_button()

def update_button():
    """Update button appearance based on current state"""
    config = load_config()
    enabled = config.get("enabled", True)
    status_text = f"🌙 {'ON' if enabled else 'OFF'}"
    btn.config(
        text=status_text,
        bg="#2ECC71" if enabled else "#95A5A6",
        fg="white",
        activebackground="#27AE60" if enabled else "#7F8C8D"
    )
    root.title(f"Redshift Scheduler - {status_text}")

def on_closing():
    """Handle window close"""
    root.quit()

# Create main window
root = tk.Tk()
root.title("Redshift Scheduler")
root.geometry("180x100")
root.resizable(False, False)

# Create toggle button
btn = tk.Button(
    root,
    command=toggle_enabled,
    font=("Arial", 24, "bold"),
    width=8,
    height=2,
    relief=tk.RAISED,
    bd=3
)
btn.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

update_button()

root.protocol("WM_DELETE_WINDOW", on_closing)
root.mainloop()
APPLET_SCRIPT

chmod +x ~/.local/bin/redshift-scheduler-applet

# ============================================
# 4. CREATE CONFIG FILE
# ============================================
echo -e "${GREEN}⚙️  Creating configuration...${NC}"
cat > ~/.config/redshift-scheduler/config.json << 'CONFIG'
{
  "enabled": true,
  "start_hour": 21,
  "end_hour": 8,
  "temperature": 4500
}
CONFIG

echo -e "${YELLOW}📝 Config file: ~/.config/redshift-scheduler/config.json${NC}"
cat ~/.config/redshift-scheduler/config.json

# ============================================
# 5. CREATE SYSTEMD SERVICES
# ============================================
echo -e "${GREEN}🔧 Creating systemd user services...${NC}"

# Daemon service
cat > ~/.config/systemd/user/redshift-scheduler-daemon.service << 'DAEMON_SERVICE'
[Unit]
Description=Redshift Scheduler Daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=%h/.local/bin/redshift-scheduler-daemon
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
DAEMON_SERVICE

# Applet service (GUI)
cat > ~/.config/systemd/user/redshift-scheduler-applet.service << 'APPLET_SERVICE'
[Unit]
Description=Redshift Scheduler Applet
PartOf=graphical-session.target
After=graphical-session-pre.target

[Service]
Type=simple
ExecStart=sh -c 'DISPLAY=${DISPLAY:-:0} %h/.local/bin/redshift-scheduler-applet'
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"

[Install]
WantedBy=graphical-session.target
APPLET_SERVICE

# ============================================
# 6. FIX SYSTEMD (MX Linux issue)
# ============================================
echo -e "${GREEN}🔧 Fixing systemd (MX Linux compatibility)...${NC}"

# Kill stuck systemd processes
pkill -f "systemd1" 2>/dev/null || true
sleep 1

# Reload daemon with error handling
echo -e "${YELLOW}Reloading systemd daemon...${NC}"
if ! systemctl --user daemon-reload 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Systemd reload issue - retrying with delay...${NC}"
    sleep 2
    systemctl --user daemon-reload 2>/dev/null || true
fi

# ============================================
# 7. ENABLE AND START SERVICES
# ============================================
echo -e "${GREEN}✅ Enabling services...${NC}"
systemctl --user enable redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user enable redshift-scheduler-applet.service 2>/dev/null || true

echo -e "${GREEN}🚀 Starting services...${NC}"
systemctl --user start redshift-scheduler-daemon.service 2>/dev/null || true
systemctl --user start redshift-scheduler-applet.service 2>/dev/null || true

sleep 2

# ============================================
# 8. VERIFY INSTALLATION
# ============================================
echo -e "${GREEN}📊 Verifying installation...${NC}"

echo -e "\n${YELLOW}Daemon status:${NC}"
systemctl --user status redshift-scheduler-daemon.service --no-pager 2>/dev/null || echo "ℹ️  Service starting..."

echo -e "\n${YELLOW}Applet status:${NC}"
systemctl --user status redshift-scheduler-applet.service --no-pager 2>/dev/null || echo "ℹ️  Service starting..."

echo -e "\n${YELLOW}Running processes:${NC}"
RUNNING=$(ps aux | grep redshift-scheduler | grep -v grep | wc -l)
if [ $RUNNING -gt 0 ]; then
    echo "✅ Found $RUNNING running processes:"
    ps aux | grep redshift-scheduler | grep -v grep
else
    echo "⚠️  No processes running yet - they will start on next login"
fi

# ============================================
# 9. INSTALLATION SUMMARY
# ============================================
echo -e "\n${GREEN}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ INSTALLATION COMPLETE!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📁 Installed files:${NC}"
echo "  • Daemon:  ~/.local/bin/redshift-scheduler-daemon"
echo "  • Applet:  ~/.local/bin/redshift-scheduler-applet"
echo "  • Config:  ~/.config/redshift-scheduler/config.json"
echo "  • Services: ~/.config/systemd/user/"

echo -e "\n${YELLOW}🔧 Useful commands:${NC}"
echo "  • Check daemon:  systemctl --user status redshift-scheduler-daemon"
echo "  • Check applet:  systemctl --user status redshift-scheduler-applet"
echo "  • View logs:     journalctl --user -u redshift-scheduler-daemon -f"
echo "  • Edit config:   nano ~/.config/redshift-scheduler/config.json"
echo "  • Manual start:  ~/.local/bin/redshift-scheduler-daemon &"
echo "  • Manual applet: DISPLAY=:0 ~/.local/bin/redshift-scheduler-applet &"

echo -e "\n${YELLOW}🔄 Next steps:${NC}"
echo "  1. Run NOW (manual start):"
echo "     ~/.local/bin/redshift-scheduler-daemon &"
echo "     DISPLAY=:0 ~/.local/bin/redshift-scheduler-applet &"
echo "  2. Logout/Login OR reboot for autostart"
echo "  3. Click 🌙 button in panel to toggle ON/OFF"
echo "  4. Edit config.json to change start/end times"

echo -e "\n${GREEN}Happy coding! 🚀${NC}\n"
