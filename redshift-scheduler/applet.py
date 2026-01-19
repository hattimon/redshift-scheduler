#!/usr/bin/env python3
import os
import sys
import json
import gi
import signal
import threading
from gi.repository import Gtk, GdkPixbuf, GLib

# Fix Gtk version conflict (MX Linux)
try:
    gi.require_version('Gtk', '3.0')
except ValueError:
    pass  # Already loaded

from gi.repository import Gtk, GdkPixbuf, GLib

class RedshiftApplet(Gtk.StatusIcon):
    def __init__(self):
        super().__init__()
        self.set_from_icon_name('night-light')
        self.set_tooltip_text("Redshift Scheduler")
        self.set_title("Redshift")
        self.connect("activate", self.on_activate)
        self.connect("popup-menu", self.on_popup)
        
        self.config_path = os.path.expanduser("~/.config/redshift-scheduler/config.json")
        self.load_config()
        
    def load_config(self):
        try:
            with open(self.config_path, 'r') as f:
                self.config = json.load(f)
        except:
            self.config = {"enabled": True}
    
    def on_activate(self, icon):
        self.toggle_redshift()
    
    def toggle_redshift(self):
        self.config["enabled"] = not self.config["enabled"]
        self.save_config()
        self.update_tooltip()
    
    def save_config(self):
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)
        with open(self.config_path, 'w') as f:
            json.dump(self.config, f)
    
    def update_tooltip(self):
        status = "ON" if self.config["enabled"] else "OFF"
        self.set_tooltip_text(f"Redshift {status}")
    
    def on_popup(self, icon, button, time):
        menu = Gtk.Menu()
        toggle_item = Gtk.MenuItem(label="Toggle Redshift")
        toggle_item.connect("activate", lambda x: self.toggle_redshift())
        quit_item = Gtk.MenuItem(label="Quit")
        quit_item.connect("activate", lambda x: Gtk.main_quit())
        menu.append(toggle_item)
        menu.append(quit_item)
        menu.show_all()
        menu.popup(None, None, None, self, button, time)

if __name__ == "__main__":
    app = RedshiftApplet()
    app.update_tooltip()
    signal.signal(signal.SIGINT, signal.SIG_DFL)
    Gtk.main()
