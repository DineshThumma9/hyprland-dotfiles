#!/usr/bin/env bash
# wlogout-wrapper.sh
# Launches wlogout and restarts waybar afterward if it's no longer running.
# Fixes: waybar disappearing after wlogout on first boot.

# Launch wlogout and WAIT for it to exit (no &)
wlogout --protocol layer-shell

# wlogout has exited (user cancelled or action completed)
# Give compositor a moment to settle
sleep 0.3

# Restart waybar only if it's not already running
if ! pgrep -x waybar > /dev/null; then
    waybar &
fi
