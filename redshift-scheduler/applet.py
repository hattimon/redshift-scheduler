#!/usr/bin/env python3
"""
XFCE Tray Applet for Redshift Scheduler
"""

import subprocess
import json
import sys
from pathlib import Path
from gi.repository import Gtk, GdkPixbuf, GLib
import gi
gi.require_version('Gtk', '3.0')

CONFIG_FILE = Path.home() / ".config/redshift-scheduler/config.json"

class RedshiftApplet:
    def __init__(self):
        self.icon = Gtk.StatusIcon()
        self.icon.connect("popup-menu", self.on_popup_menu)
        self.icon.connect("activate", self.on_activate)
        self.update_icon()
        GLib.timeout_add_seconds(5, self.update_icon)

    def load_config(self):
        if CONFIG_FILE.exists():
            with open(CONFIG_FILE) as f:
                return json.load(f)
        return {}

    def save_config(self, config):
        with open(CONFIG_FILE, 'w') as f:
            json.dump(config, f, indent=2)

    def update_icon(self):
        config = self.load_config()
        icon_path = Path.home() / ".local/share/redshift-scheduler/icons"
        if config.get("enabled"):
            icon = str(icon_path / "redshift-on.svg")
        else:
            icon = str(icon_path / "redshift-off.svg")
        
        try:
            pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(icon, 24, 24, True)
            self.icon.set_from_pixbuf(pixbuf)
        except:
            self.icon.set_from_icon_name("redshift")
        
        return True

    def on_activate(self, icon):
        """Toggle on/off on click"""
        config = self.load_config()
        config["enabled"] = not config.get("enabled", True)
        self.save_config(config)
        subprocess.run("systemctl --user restart redshift-scheduler", shell=True)
        self.update_icon()

    def on_popup_menu(self, icon, button, time):
        """Show context menu"""
        menu = Gtk.Menu()
        
        # Enable/Disable
        config = self.load_config()
        toggle_label = "Disable" if config.get("enabled") else "Enable"
        toggle = Gtk.MenuItem(toggle_label)
        toggle.connect("activate", lambda w: self.on_activate(None))
        menu.append(toggle)
        
        menu.append(Gtk.SeparatorMenuItem())
        
        # Temperature presets
        for temp in [4500, 5500, 6500]:
            item = Gtk.MenuItem(f"Temperature {temp}K")
            item.connect("activate", self.set_temp, temp)
            menu.append(item)
        
        menu.append(Gtk.SeparatorMenuItem())
        
        # Settings
        settings = Gtk.MenuItem("Settings")
        settings.connect("activate", self.open_settings)
        menu.append(settings)
        
        # Exit
        exit_item = Gtk.MenuItem("Exit")
        exit_item.connect("activate", Gtk.main_quit)
        menu.append(exit_item)
        
        menu.show_all()
        menu.popup_at_pointer(None)

    def set_temp(self, widget, temp):
        """Set temperature"""
        subprocess.run(f"redshift -O {temp}", shell=True)

    def open_settings(self, widget):
        """Launch GUI config"""
        subprocess.Popen("redshift-scheduler-config")

    def run(self):
        """Start applet"""
        Gtk.main()

if __name__ == "__main__":
    applet = RedshiftApplet()
    applet.run()
