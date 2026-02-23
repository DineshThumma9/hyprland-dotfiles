#!/usr/bin/env bash

# ============================================================================
# Theme Mode Switcher - Switch between DEFAULT and MATUGEN color modes
# ============================================================================
# This script toggles between your default static colors and matugen-generated
# dynamic colors across all your configs
# ============================================================================

set -e

CONFIG_DIR="$HOME/.config"
CACHE_DIR="$HOME/.cache"
MODE_FILE="$CONFIG_DIR/themes/.current-mode"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Configuration Files to Update
# ============================================================================
declare -A CONFIGS=(
    ["waybar"]="$CONFIG_DIR/waybar/style.css"
    ["swaync"]="$CONFIG_DIR/swaync/style.css"
    ["wlogout"]="$CONFIG_DIR/wlogout/style.css"
)

# ============================================================================
# Functions
# ============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║         🎨 Theme Mode Switcher 🎨                       ║"
    echo "║    Switch between DEFAULT and MATUGEN colors            ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

get_current_mode() {
    if [ -f "$MODE_FILE" ]; then
        cat "$MODE_FILE"
    else
        echo "default"
    fi
}

# Function to switch a CSS file to DEFAULT mode
switch_to_default() {
    local file="$1"
    local name="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "  ${YELLOW}⚠${NC} Skipping $name (file not found)"
        return
    fi
    
    # Check if file uses colors.css
    if ! grep -q "colors.css" "$file"; then
        echo -e "  ${YELLOW}⚠${NC} Skipping $name (no colors.css import found)"
        return
    fi
    
    # Create a temporary file with the correct format
    python3 - "$file" << 'PYEOF'
import sys
import re

with open(sys.argv[1], 'r') as f:
    content = f.read()

# Enable default colors.css import (uncomment it)
content = re.sub(r'/\* (@import "colors\.css";) \*/', r'\1', content)

# Disable matugen import (keep it in the multi-line comment block)
# Find the matugen section and ensure the import line is commented
content = re.sub(
    r'(/\* MATUGEN THEME[^\n]*\n)(@import "[^"]*matugen-colors[^"]*";)',
    r'\1/* \2 */',
    content
)

with open(sys.argv[1], 'w') as f:
    f.write(content)
PYEOF
    
    echo -e "  ${GREEN}✓${NC} Updated $name"
}

# Function to switch a CSS file to MATUGEN mode
switch_to_matugen() {
    local file="$1"
    local name="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "  ${YELLOW}⚠${NC} Skipping $name (file not found)"
        return
    fi
    
    # Create a temporary file with the correct format
    python3 - "$file" << 'PYEOF'
import sys
import re

with open(sys.argv[1], 'r') as f:
    content = f.read()

# Disable default colors.css import (comment it)
content = re.sub(r'^(@import "colors\.css";)$', r'/* \1 */', content, flags=re.MULTILINE)

# Enable matugen import (uncomment it from the multi-line comment)
content = re.sub(
    r'(/\* MATUGEN THEME[^\n]*\n)/\* (@import "[^"]*matugen-colors[^"]*";) \*/',
    r'\1\2',
    content
)

with open(sys.argv[1], 'w') as f:
    f.write(content)
PYEOF
    
    echo -e "  ${GREEN}✓${NC} Updated $name"
}

# Function to reload services
reload_services() {
    echo -e "\n${BLUE}Reloading services...${NC}"
    
    # Reload waybar
    if pgrep waybar >/dev/null; then
        pkill -SIGUSR2 waybar 2>/dev/null || killall -SIGUSR2 waybar 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Reloaded waybar"
    fi
    
    # Reload swaync
    if pgrep swaync >/dev/null; then
        swaync-client -rs 2>/dev/null || true
        echo -e "  ${GREEN}✓${NC} Reloaded swaync"
    fi
    
    # Note about wlogout - it doesn't need reload as it's not persistent
}

# Function to apply DEFAULT mode
apply_default() {
    echo -e "\n${BLUE}Switching to DEFAULT theme mode...${NC}\n"
    
    for name in "${!CONFIGS[@]}"; do
        switch_to_default "${CONFIGS[$name]}" "$name"
    done
    
    echo "default" > "$MODE_FILE"
    reload_services
    
    echo -e "\n${GREEN}✔ Successfully switched to DEFAULT mode${NC}"
    echo -e "Your custom static colors are now active.\n"
    
    # Send notification
    if command -v notify-send &> /dev/null; then
        notify-send "Theme Mode Changed" "Switched to DEFAULT colors" -t 3000 -i preferences-desktop-theme
    fi
}

# Function to apply MATUGEN mode
apply_matugen() {
    echo -e "\n${BLUE}Switching to MATUGEN theme mode...${NC}\n"
    
    # Check if matugen cache files exist
    local matugen_exists=false
    if [ -f "$CACHE_DIR/matugen-colors-waybar.css" ] || \
       [ -f "$CACHE_DIR/matugen-colors-swaync.css" ] || \
       [ -f "$CACHE_DIR/matugen-colors-wlogout.css" ]; then
        matugen_exists=true
    fi
    
    if [ "$matugen_exists" = false ]; then
        echo -e "${YELLOW}⚠ Warning: No matugen cache files found${NC}"
        echo -e "Running matugen to generate colors...\n"
        
        if command -v matugen &> /dev/null; then
            matugen image "$HOME/Downloads/Wallpapers/wallhaven-yq5ywl.jpg" 2>/dev/null || {
                echo -e "${RED}✘ Failed to run matugen${NC}"
                echo -e "Please run 'matugen image /path/to/your/wallpaper.jpg' manually"
                exit 1
            }
        else
            echo -e "${RED}✘ Error: matugen is not installed${NC}"
            echo -e "Install it first: https://github.com/InioX/matugen"
            exit 1
        fi
    fi
    
    for name in "${!CONFIGS[@]}"; do
        switch_to_matugen "${CONFIGS[$name]}" "$name"
    done
    
    echo "matugen" > "$MODE_FILE"
    reload_services
    
    echo -e "\n${GREEN}✔ Successfully switched to MATUGEN mode${NC}"
    echo -e "Colors are now generated from your wallpaper.\n"
    
    # Send notification
    if command -v notify-send &> /dev/null; then
        notify-send "Theme Mode Changed" "Switched to MATUGEN colors" -t 3000 -i preferences-desktop-theme
    fi
}

# Function to toggle between modes
toggle_mode() {
    local current_mode=$(get_current_mode)
    
    if [ "$current_mode" = "default" ]; then
        apply_matugen
    else
        apply_default
    fi
}

# Function to show current mode
show_status() {
    local current_mode=$(get_current_mode)
    
    print_banner
    echo -e "${BLUE}Current Mode:${NC} "
    
    if [ "$current_mode" = "default" ]; then
        echo -e "  ${GREEN}● DEFAULT${NC} - Using static custom colors"
        echo -e "  ○ MATUGEN - Dynamic wallpaper-based colors"
    else
        echo -e "  ○ DEFAULT - Using static custom colors"
        echo -e "  ${GREEN}● MATUGEN${NC} - Dynamic wallpaper-based colors"
    fi
    
    echo -e "\n${BLUE}Configs managed:${NC}"
    for name in "${!CONFIGS[@]}"; do
        if [ -f "${CONFIGS[$name]}" ]; then
            echo -e "  ${GREEN}✓${NC} $name"
        else
            echo -e "  ${RED}✘${NC} $name (not found)"
        fi
    done
    echo ""
}

# Function to show interactive menu
show_menu() {
    print_banner
    show_status
    
    echo -e "${YELLOW}Select an option:${NC}"
    echo -e "  ${GREEN}1)${NC} Switch to DEFAULT mode"
    echo -e "  ${GREEN}2)${NC} Switch to MATUGEN mode"
    echo -e "  ${GREEN}3)${NC} Toggle mode"
    echo -e "  ${GREEN}4)${NC} Show status"
    echo -e "  ${GREEN}5)${NC} Exit"
    echo ""
    
    read -p "Enter choice [1-5]: " choice
    
    case $choice in
        1) apply_default ;;
        2) apply_matugen ;;
        3) toggle_mode ;;
        4) show_status ;;
        5) exit 0 ;;
        *) 
            echo -e "${RED}Invalid choice${NC}"
            exit 1
            ;;
    esac
}

# ============================================================================
# Main Script
# ============================================================================

# Create themes directory if it doesn't exist
mkdir -p "$(dirname "$MODE_FILE")"

# Parse command line arguments
case "${1:-menu}" in
    default)
        apply_default
        ;;
    matugen)
        apply_matugen
        ;;
    toggle)
        toggle_mode
        ;;
    status)
        show_status
        ;;
    menu)
        show_menu
        ;;
    *)
        echo "Usage: $0 {default|matugen|toggle|status|menu}"
        echo ""
        echo "Options:"
        echo "  default  - Switch to default static colors"
        echo "  matugen  - Switch to matugen wallpaper-based colors"
        echo "  toggle   - Toggle between default and matugen"
        echo "  status   - Show current mode"
        echo "  menu     - Show interactive menu (default)"
        exit 1
        ;;
esac
