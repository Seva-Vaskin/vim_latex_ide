#!/bin/bash

inkscape-figures watch
python3 /inkscape-shortcut-manager/main.py >>/dev/null 2>&1 &
# service dbus start
# export $(dbus-launch)

xpra start :80 --bind-tcp=0.0.0.0:8080 --xvfb="Xvfb +extension Composite -screen 0 5760x2560x24+32 -dpi 155 -nolisten tcp -noreset -auth \$XAUTHORITY"

exec bash