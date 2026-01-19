#!/usr/bin/env python3
"""
Redshift Scheduler Settings GUI
"""

import PySimpleGUI as sg
import json
from pathlib import Path
import subprocess

CONFIG_FILE = Path.home() / ".config/redshift-scheduler/config.json"

class RedshiftConfigGUI:
    def __init__(self):
        sg.theme('DarkBlue3')
        self.config = self.load_config()

    def load_config(self):
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE) as f:
                return json.load(f)
        return {"schedule": {"start": "21:00", "stop": "08:00"}, 
                "temps": {"day": 5800, "night": 4800}}

    def show(self):
        """Display settings window"""
        layout = [
            [sg.Text("Redshift Scheduler Settings", font=("Arial", 16, "bold"))],
            [sg.Text("Night Mode Schedule", font=("Arial", 12))],
            [sg.Text("Start:"), sg.Input(self.config["schedule"]["start"], key="start", size=(10,))],
            [sg.Text("Stop:"), sg.Input(self.config["schedule"]["stop"], key="stop", size=(10,))],
            
            [sg.Text("Temperatures (Kelvin)", font=("Arial", 12))],
            [sg.Text("Day:"), sg.Input(self.config["temps"]["day"], key="temp_day", size=(10,))],
            [sg.Text("Night:"), sg.Input(self.config["temps"]["night"], key="temp_night", size=(10,))],
            
            [sg.Button("Save"), sg.Button("Cancel")],
        ]
        
        window = sg.Window("Redshift Scheduler", layout)
        
        while True:
            event, values = window.read()
            if event in [sg.WINDOW_CLOSED, "Cancel"]:
                break
            if event == "Save":
                self.config["schedule"]["start"] = values["start"]
                self.config["schedule"]["stop"] = values["stop"]
                self.config["temps"]["day"] = int(values["temp_day"])
                self.config["temps"]["night"] = int(values["temp_night"])
                
                CONFIG_FILE.parent.mkdir(parents=True, exist_ok=True)
                with open(CONFIG_FILE, 'w') as f:
                    json.dump(self.config, f, indent=2)
                
                subprocess.run("systemctl --user restart redshift-scheduler", shell=True)
                sg.popup("Settings saved!", "Changes applied.")
                break
        
        window.close()

if __name__ == "__main__":
    gui = RedshiftConfigGUI()
    gui.show()
