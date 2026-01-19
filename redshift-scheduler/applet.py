#!/usr/bin/env python3
import os
import sys
import json
import gi
import signal

# MX Linux Gtk3 fix
try:
    gi.require_version('Gtk', '3.0')
except:
    pass

try:
    gi.require_version('AppIndicator3', '0.1')
except:
    print("Install libappindicator3-1")
    sys.exit(1)

from gi.repository import Gtk, AppIndicator3 as AppIndicator, GLib

class RedshiftTray:
    def __init__(self):
        self.ind = AppIndicator.Indicator.new(
            "redshift-scheduler",
            "night-light",
            AppIndicator.IndicatorCategory.APPLICATION_STATUS
        )
        self.ind.set_status(AppIndicator.IndicatorStatus.ACTIVE)
        self.ind.set_title("Redshift Scheduler")
        
        self.config_path = os.path.expanduser("~/.config/redshift-scheduler/config.json")
        self.config = self.load_config()
        self.update_icon()
        
        menu = Gtk.Menu()
        toggle = Gtk.MenuItem(label="Toggle Redshift")
        toggle.connect("activate", self.toggle)
        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", Gtk.main_quit)
        
        menu.append(toggle)
        menu.append(quit_item)
        menu.show_all()
        self.ind.set_menu(menu)
    
    def load_config(self):
        try:
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                return {"enabled": config.get("enabled", True)}
        except:
            return {"enabled": True}
    
    def update_icon(self):
        icon = "night-light-on-symbolic" if self.config["enabled"] else "night-light-off-symbolic"
        self.ind.set_icon(icon)
        self.ind.set_label("ON" if self.config["enabled"] else "OFF")
    
    def toggle(self, widget):
        self.config["enabled"] = not self.config["enabled"]
        self.save_config()
        self.update_icon()
    
    def save_config(self):
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        config = {"enabled": self.config["enabled"]}
        with open(self.config_path, 'w') as f:
            json.dump(config, f)
    
    def run(self):
        GLib.MainLoop().run()

if __name__ == "__main__":
    tray = RedshiftTray()
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    tray.run()
