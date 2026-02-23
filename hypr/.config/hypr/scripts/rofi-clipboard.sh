#!/usr/bin/env bash

# Directories for image cache
CACHE_DIR="$HOME/.cache/cliphist/thumbnails"
mkdir -p "$CACHE_DIR"

# Source the central rofi theme to maintain our unified aesthetic!
source "$HOME/.config/rofi/theme.env"

# Read top 50 clipboard items for snappy performance
readarray -t lines < <(cliphist list | head -n 50)

for line in "${lines[@]}"; do
    # Extract the ID and the raw content
    id=$(echo "$line" | awk '{print $1}')
    content=$(echo "$line" | cut -f2-)
    
    # Check if the row contains an image
    if [[ "$content" == *"[[ binary"* ]]; then
        # Define where to save the decoded thumbnail
        img_path="$CACHE_DIR/${id}.png"
        
        # Decode the image and save to cache securely if not already stored
        if [ ! -f "$img_path" ]; then
            echo "$line" | cliphist decode > "$img_path"
        fi
        
        # Send to rofi: 
        # 1. Output the raw line so `cliphist decode` can read it when selected
        # 2. Use `\0display\x1f` to hide the ugly ID numbers.
        # 3. Use `\x1ficon\x1f` to attach the physical thumbnail file path!
        echo -en "${line}\0display\x1f\x1ficon\x1f${img_path}\n"
    else
        # It's normal text. Truncate it to look clean, and hide the ID number!
        display_text=$(echo "$content" | cut -c 1-80)
        echo -en "${line}\0display\x1f${display_text}\n"
    fi
done | rofi -dmenu -theme "$ROFI_THEME" -p "Clipboard" -show-icons -theme-str 'listview {columns: 1;}' | cliphist decode | wl-copy

# Keep the cache lightweight by auto-deleting thumbnails older than 1 day
find "$CACHE_DIR" -type f -mmin +1440 -delete
