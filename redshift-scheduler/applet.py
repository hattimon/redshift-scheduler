#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
import os
import json
import subprocess
import signal

class RedshiftApp(Gtk.Application):
    def __init__(self):
        super().__init__()
        self.config_path = os.path.expanduser("~/.config/redshift-scheduler/config.json")
        self.config = self.load_config()
    
    def do_activate(self):
        win = Gtk.Window(application=self)
        win.set_title("Redshift Scheduler")
        win.set_default_size(150, 50)
        win.set_type_hint(Gtk.WindowType.POPUP)
        win.set_keep_above(True)
        win.move(50, 50)
        
        button = Gtk.Button(label="🌙 ON" if self.config["enabled"] else "☀️ OFF")
        button.connect("clicked", self.toggle_redshift)
        win.add(button)
        win.show_all()
    
    def load_config(self):
        try:
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                return {"enabled": config.get("enabled", True)}
        except:
            return {"enabled": True}
    
    def save_config(self):
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        with open(self.config_path, 'w') as f:
            json.dump(self.config, f)
    
    def toggle_redshift(self, widget):
        self.config["enabled"] = not self.config["enabled"]
        self.save_config()
        
        subprocess.run(["killall", "redshift"], check=False)
        if self.config["enabled"]:
            subprocess.Popen(["redshift", "-O", "4800"])
        else:
            subprocess.Popen(["redshift", "-x"])

if __name__ == "__main__":
    app = RedshiftApp()
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    app.run()
