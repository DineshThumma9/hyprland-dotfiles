#!/bin/bash

# Wlogout launcher script with blur support

# Check if wlogout is already running
if pgrep -x "wlogout" > /dev/null
then
    pkill -x wlogout
    exit 0
fi

# Launch wlogout with layer name for blur effect
wlogout --layer-shell --css ~/.config/wlogout/style.css --layout ~/.config/wlogout/layout --buttons-per-row 3 --margin-top 0 --margin-bottom 0 --margin-left 0 --margin-right 0
