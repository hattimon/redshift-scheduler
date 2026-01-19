#!/usr/bin/env python3
import os
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
    start = config["schedule"]["start"]
    stop = config["schedule"]["stop"]
    
    if start < stop:
        return start <= now <= stop
    else:
        return now >= start or now <= stop

def set_redshift(enabled, temp):
    try:
        subprocess.run(["killall", "redshift"], check=False, stderr=subprocess.DEVNULL)
        if enabled:
            subprocess.Popen(["redshift", "-O", str(temp)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            subprocess.Popen(["redshift", "-x"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except:
        pass

def main():
    current_state = None
    
    while True:
        try:
            config = load_config()
            
            if config["enabled"]:
                if is_night_time(config):
                    new_state = ("night", config["temps"]["night"])
                else:
                    new_state = ("day", config["temps"]["day"])
            else:
                new_state = ("off", 6500)
            
            if new_state != current_state:
                if new_state[0] == "off":
                    set_redshift(False, new_state[1])
                else:
                    set_redshift(True, new_state[1])
                current_state = new_state
            
            time.sleep(60)
        except KeyboardInterrupt:
            set_redshift(False, 6500)
            break
        except Exception:
            time.sleep(60)

if __name__ == "__main__":
    main()
