#!/usr/bin/env python3
"""
Redshift Scheduler Daemon
- Harmonogram noc/dzień
- Kontrola redshift'a
- System notifications
"""

import subprocess
import json
import sys
import os
from datetime import datetime
from pathlib import Path
import signal
import time

CONFIG_FILE = Path.home() / ".config/redshift-scheduler/config.json"
STATUS_FILE = Path("/tmp/redshift-scheduler.status")
LOCK_FILE = Path("/tmp/redshift-scheduler.pid")

class RedshiftScheduler:
    def __init__(self):
        self.config = self.load_config()
        self.running = True
        self.redshift_pid = None
        signal.signal(signal.SIGTERM, self.stop)
        signal.signal(signal.SIGINT, self.stop)

    def load_config(self):
        """Load config or create default"""
        if not CONFIG_FILE.exists():
            CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
            default = {
                "enabled": True,
                "schedule": {"start": "21:00", "stop": "08:00"},
                "temps": {"day": 5800, "night": 4800},
                "location": {"lat": 50.0, "lon": 15.0}
            }
            with open(CONFIG_FILE, 'w') as f:
                json.dump(default, f, indent=2)
            return default
        with open(CONFIG_FILE) as f:
            return json.load(f)

    def is_night_mode(self):
        """Check if current time is in night schedule"""
        now = datetime.now().strftime("%H:%M")
        start = self.config["schedule"]["start"]
        stop = self.config["schedule"]["stop"]
        
        if start < stop:  # e.g., 09:00 - 18:00
            return start <= now < stop
        else:  # e.g., 21:00 - 08:00 (crosses midnight)
            return now >= start or now < stop

    def get_temp(self):
        """Get current target temperature"""
        return self.config["temps"]["night"] if self.is_night_mode() else self.config["temps"]["day"]

    def start_redshift(self):
        """Start redshift with config"""
        if self.redshift_pid:
            return
        
        temp = self.get_temp()
        cmd = f"redshift -O {temp}"
        self.redshift_pid = subprocess.Popen(cmd, shell=True).pid
        self.notify(f"Redshift: {temp}K mode")
        self.save_status("on")

    def stop_redshift(self):
        """Stop redshift"""
        subprocess.run("pkill redshift", shell=True)
        self.redshift_pid = None
        self.notify("Redshift disabled")
        self.save_status("off")

    def save_status(self, status):
        """Save status for applet"""
        with open(STATUS_FILE, 'w') as f:
            f.write(f"{status}\n{self.get_temp()}")

    def notify(self, msg):
        """Send notification"""
        subprocess.run(f"notify-send 'Redshift' '{msg}'", shell=True)

    def run(self):
        """Main daemon loop"""
        with open(LOCK_FILE, 'w') as f:
            f.write(str(os.getpid()))
        
        last_state = None
        while self.running:
            if not self.config["enabled"]:
                self.stop_redshift()
                time.sleep(10)
                continue
            
            current_state = self.is_night_mode()
            if current_state != last_state:
                if current_state:
                    self.start_redshift()
                else:
                    self.stop_redshift()
                last_state = current_state
            
            time.sleep(30)  # Check every 30s

    def stop(self, signum, frame):
        """Handle shutdown"""
        self.running = False
        self.stop_redshift()
        sys.exit(0)

if __name__ == "__main__":
    scheduler = RedshiftScheduler()
    scheduler.run()
