#!/usr/bin/env bash

# ============================================================================
# Rofi Color Scheme Switcher
# ============================================================================
# Quickly switch rofi colors across ALL rofi instances
# (app launcher, clipboard, wifi, bluetooth, etc.)
# ============================================================================

CONFIG_DIR="$HOME/.config/rofi"
COLORS_DIR="$CONFIG_DIR/colors"

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}Available Rofi Color Schemes:${NC}\n"

# List available color schemes
select color_scheme in adapta arc black catppuccin cyberpunk dracula everforest gruvbox lovelace navy nord onedark paper solarized tokyonight yousai; do
    if [ -n "$color_scheme" ]; then
        if [ -f "$COLORS_DIR/$color_scheme.rasi" ]; then
            echo -e "\n${GREEN}Applying color scheme: ${YELLOW}$color_scheme${NC}\n"
            
            # Update the main colors.rasi file
            cat > "$CONFIG_DIR/colors.rasi" << EOF
* {
    /* Color Palette: $color_scheme */
@import "$COLORS_DIR/$color_scheme.rasi"
}
EOF
            
            echo -e "${GREEN}✓ Color scheme applied successfully!${NC}"
            echo -e "${CYAN}This will affect:${NC}"
            echo "  • App launcher (Super+R)"
            echo "  • Clipboard manager (Super+V)"
            echo "  • WiFi menu"
            echo "  • Bluetooth menu"
            echo ""
            echo "Tip: Your theme switcher will override this when you change themes."
            break
        else
            echo -e "${RED}Color scheme file not found!${NC}"
        fi
    fi
done
