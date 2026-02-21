#!/usr/bin/env bash
# bt-autoconnect.sh
# Waits for bluetooth adapter to be up, then connects all trusted paired devices.
# Add to autostart: exec-once = ~/.config/hypr/scripts/bt-autoconnect.sh

# Wait for bluetooth service to be ready
sleep 5

# Power on adapter if not already on
bluetoothctl power on

# Give it a moment
sleep 2

# Connect all paired/trusted devices
bluetoothctl paired-devices | awk '{print $2}' | while read -r mac; do
    bluetoothctl connect "$mac" &
done
