#!/usr/bin/env python3
import os
import sys
import json
import time
import subprocess
import datetime
from pathlib import Path

CONFIG_PATH = Path.home() / ".config/redshift-scheduler/config.json"

def load_config():
    default = {
        "enabled": True,
        "schedule": {"start": "21:00", "stop": "08:00"},
        "temps": {"day": 5800, "night": 4800}
    }
    try:
        with open(CONFIG_PATH, 'r') as f:
            config = json.load(f)
        return {**default, **config}
    except:
        return default

def is_night_time(config):
    now = datetime.datetime.now().strftime("%H:%M")
    return config["schedule"]["start"] <= now or now <= config["schedule"]["stop"]

def set_redshift(enabled, night_temp):
    try:
        if enabled:
            subprocess.run(["redshift", "-O", str(night_temp)], check=False)
        else:
            subprocess.run(["redshift", "-x"], check=False)
    except:
        pass

def main():
    config = load_config()
    
    while True:
        try:
            config = load_config()
            
            if config["enabled"]:
                if is_night_time(config):
                    set_redshift(True, config["temps"]["night"])
                else:
                    set_redshift(False, config["temps"]["day"])
            
            time.sleep(60)  # Check every minute
        except KeyboardInterrupt:
            set_redshift(False, 6500)
            break
        except Exception:
            time.sleep(60)

if __name__ == "__main__":
    main()
