#!/bin/bash

# Path to your config file
CONFIG_FILE="$HOME/.config/hypr/binds.conf"

# 1. Define the "Summary" lines you want at the top
#    (We manually add these so we don't have to list every single number key)
SUMMARY="<b>SUPER + [0-9]</b>        <span color='#81a1c1'>Switch Workspace</span>\n"
SUMMARY+="<b>SUPER + SHIFT + [0-9]</b>  <span color='#81a1c1'>Move Window to Workspace</span>\n"
SUMMARY+="<b>SUPER + Mouse</b>        <span color='#81a1c1'>Move/Resize Window</span>\n"

# 2. Read the file, filter it, and translate commands to English
#    - grep -v "workspace": Removes all the repetitive workspace lines
#    - sed replacements: Turns code into English

LIST=$(grep "bind =" "$CONFIG_FILE" | \
grep -v "workspace" | \
sed 's/bind = //g' | \
sed 's/$mainMod/SUPER/g' | \
sed 's/SUPER, /SUPER + /g' | \
sed 's/, exec, /  │  /g' | \
sed 's/, / + /g' | \
\
# --- THE DICTIONARY (Add your own translations here) ---
sed 's/kitty/Open Terminal/' | \
sed 's/firefox/Open Browser/' | \
sed 's/thunar/Open Files/' | \
sed 's/wofi --show drun/App Launcher/' | \
sed 's/killactive/Close Window/' | \
sed 's/togglefloating/Float Window/' | \
sed 's/fullscreen/Toggle Fullscreen/' | \
sed 's/grim/Take Screenshot/' | \
sed 's/slurp/Select Area/' | \
sed 's/hyprlock/Lock Screen/' | \
sed 's/wlogout/Power Menu/' | \
\
# Format the output nicely
awk -F"│" '{printf "<b>%-25s</b>  <span color=\"#eceff4\">%s</span>\n", $1, $2}')

# 3. Combine Summary + List and show in Rofi
echo -e "$SUMMARY$LIST" | \
rofi -dmenu -markup-rows \
    -p "Keybinds" \
    -theme-str 'window {width: 50%;}' \
    -theme-str 'listview {columns: 1; lines: 15;}'