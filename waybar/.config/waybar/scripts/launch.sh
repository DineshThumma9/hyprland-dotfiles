#!/bin/bash

killall -9 waybar 
killall -9 swaync 
pkill -9 dunst
pkill -9 mako
swaync-client -R && swaync-client -rs
swaync &
waybar & 
