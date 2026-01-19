#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
import os
import json
import subprocess
import signal

class RedshiftTray(Gtk.Window):
    def __init__(self):
        super().__init__(title="Redshift Scheduler")
        self.set_type_hint(Gtk.Gdk.WindowTypeHint.DOCK)
        self.set_keep_above(True)
        self.set_decorated(False)
        self.set_skip_taskbar_hint(True)
        self.move(10, 10)
        self.resize(1, 1)
        
        self.config_path = os.path.expanduser("~/.config/redshift-scheduler/config.json")
        self.config = self.load_config()
        
        self.button = Gtk.Button(label="🌙" if self.config["enabled"] else "☀️")
        self.button.connect("clicked", self.toggle)
        self.add(self.button)
        self.button.show()
        
        self.timeout = GLib.timeout_add(1000, self.update_display)
        
    def load_config(self):
        try:
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                return {"enabled": config.get("enabled", True)}
        except:
            return {"enabled": True}
    
    def save_config(self):
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        config = {"enabled": self.config["enabled"]}
        with open(self.config_path, 'w') as f:
            json.dump(config, f)
    
    def toggle(self, widget):
        self.config["enabled"] = not self.config["enabled"]
        self.save_config()
        self.update_display()
    
    def update_display(self):
        enabled = self.config["enabled"]
        self.button.set_label("🌙 ON" if enabled else "☀️ OFF")
        subprocess.run(["killall", "redshift"], check=False)
        if enabled:
            subprocess.Popen(["redshift", "-O", "4800"])
        return True
    
    def do_delete_event(self, event):
        Gtk.main_quit()
        return True

if __name__ == "__main__":
    win = RedshiftTray()
    win.show()
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    Gtk.main()
