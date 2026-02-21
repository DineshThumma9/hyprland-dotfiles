#!/usr/bin/env bash

# ============================================================================
# Theme Switcher - Unified theme management for Hyprland rice
# ============================================================================
# Changes themes for: swaync, waypaper, rofi, waybar, hyprlock, wlogout, polkit
# ============================================================================

set -e

CONFIG_DIR="$HOME/.config"
THEMES_DIR="$CONFIG_DIR/themes"
CURRENT_THEME_FILE="$THEMES_DIR/.current-theme"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Functions
# ============================================================================

print_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║          🎨 Hyprland Theme Switcher 🎨                  ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

list_themes() {
    echo -e "${BLUE}Available themes:${NC}\n"
    local i=1
    for theme in "$THEMES_DIR"/*/ ; do
        if [ -d "$theme" ]; then
            theme_name=$(basename "$theme")
            if [ -f "$theme/theme.conf" ]; then
                description=$(grep "^description=" "$theme/theme.conf" | cut -d'=' -f2 | tr -d '"')
                echo -e "  ${GREEN}$i)${NC} ${YELLOW}$theme_name${NC} - $description"
            else
                echo -e "  ${GREEN}$i)${NC} ${YELLOW}$theme_name${NC}"
            fi
            ((i++))
        fi
    done
    echo ""
}

get_current_theme() {
    if [ -f "$CURRENT_THEME_FILE" ]; then
        cat "$CURRENT_THEME_FILE"
    else
        echo "none"
    fi
}

apply_swaync() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying swaync theme..."
    
    if [ -f "$theme_dir/swaync/style.css" ]; then
        cp "$theme_dir/swaync/style.css" "$CONFIG_DIR/swaync/style.css"
    fi
    
    if [ -f "$theme_dir/swaync/config.json" ]; then
        cp "$theme_dir/swaync/config.json" "$CONFIG_DIR/swaync/config.json"
    fi
    
    # Reload swaync
    pkill -SIGUSR2 swaync 2>/dev/null || true
}

apply_waybar() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying waybar theme..."
    
    if [ -f "$theme_dir/waybar/style.css" ]; then
        cp "$theme_dir/waybar/style.css" "$CONFIG_DIR/waybar/style.css"
    fi
    
    if [ -f "$theme_dir/waybar/config.jsonc" ]; then
        cp "$theme_dir/waybar/config.jsonc" "$CONFIG_DIR/waybar/config.jsonc"
    fi
    
    # Reload waybar
    pkill -SIGUSR2 waybar 2>/dev/null || killall -SIGUSR2 waybar 2>/dev/null || true
}

apply_rofi() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying rofi theme..."
    
    if [ -f "$theme_dir/rofi/colors.rasi" ]; then
        cp "$theme_dir/rofi/colors.rasi" "$CONFIG_DIR/rofi/colors.rasi"
    fi
}

apply_wlogout() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying wlogout theme..."
    
    if [ -f "$theme_dir/wlogout/style.css" ]; then
        cp "$theme_dir/wlogout/style.css" "$CONFIG_DIR/wlogout/style.css"
    fi
    
    if [ -f "$theme_dir/wlogout/layout" ]; then
        cp "$theme_dir/wlogout/layout" "$CONFIG_DIR/wlogout/layout"
    fi
}

apply_hyprlock() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying hyprlock theme..."
    
    if [ -f "$theme_dir/hyprlock/hyprlock.conf" ]; then
        cp "$theme_dir/hyprlock/hyprlock.conf" "$CONFIG_DIR/hypr/hyprlock.conf"
    fi
}

apply_waypaper() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying wallpaper..."
    
    if [ -f "$theme_dir/theme.conf" ]; then
        wallpaper=$(grep "^wallpaper=" "$theme_dir/theme.conf" | cut -d'=' -f2 | tr -d '"')
        if [ -n "$wallpaper" ] && [ -f "$wallpaper" ]; then
            # Update waypaper config
            sed -i "s|^wallpaper = .*|wallpaper = $wallpaper|" "$CONFIG_DIR/waypaper/config.ini"
            
            # Apply wallpaper using hyprpaper
            if command -v hyprctl &> /dev/null; then
                # Preload the wallpaper
                hyprctl hyprpaper preload "$wallpaper" 2>/dev/null || true
                # Set it on all monitors
                hyprctl hyprpaper wallpaper ",$wallpaper" 2>/dev/null || true
            fi
        fi
    fi
}

apply_hyprland() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying Hyprland theme..."
    
    if [ -f "$theme_dir/hypr/theme.conf" ]; then
        cp "$theme_dir/hypr/theme.conf" "$CONFIG_DIR/hypr/themes/current.conf"
        # Reload Hyprland
        hyprctl reload 2>/dev/null || true
    fi
}

apply_kitty() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying Kitty theme..."
    
    if [ -f "$theme_dir/kitty/theme.conf" ]; then
        cp "$theme_dir/kitty/theme.conf" "$CONFIG_DIR/kitty/current-theme.conf"
        # Reload all kitty instances
        killall -SIGUSR1 kitty 2>/dev/null || true
    fi
}

apply_polkit() {
    local theme_dir="$1"
    echo -e "  ${CYAN}→${NC} Applying polkit theme..."
    
    # polkit-kde uses Qt theming, we can set some env vars or create a custom stylesheet
    if [ -f "$theme_dir/polkit/polkit.css" ]; then
        mkdir -p "$CONFIG_DIR/polkit-kde"
        cp "$theme_dir/polkit/polkit.css" "$CONFIG_DIR/polkit-kde/polkit.css"
    fi
}

apply_theme() {
    local theme_name="$1"
    local theme_dir="$THEMES_DIR/$theme_name"
    
    if [ ! -d "$theme_dir" ]; then
        echo -e "${RED}✗ Theme '$theme_name' not found!${NC}"
        exit 1
    fi
    
    echo -e "\n${PURPLE}Applying theme: ${YELLOW}$theme_name${NC}\n"
    
    # Apply each component
    apply_hyprland "$theme_dir"
    apply_kitty "$theme_dir"
    apply_swaync "$theme_dir"
    apply_waybar "$theme_dir"
    apply_rofi "$theme_dir"
    apply_wlogout "$theme_dir"
    apply_hyprlock "$theme_dir"
    apply_waypaper "$theme_dir"
    apply_polkit "$theme_dir"
    
    # Save current theme
    echo "$theme_name" > "$CURRENT_THEME_FILE"
    
    echo -e "\n${GREEN}✓ Theme '$theme_name' applied successfully!${NC}\n"
}

create_theme_template() {
    local theme_name="$1"
    local theme_dir="$THEMES_DIR/$theme_name"
    
    if [ -d "$theme_dir" ]; then
        echo -e "${RED}✗ Theme '$theme_name' already exists!${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Creating theme template: ${YELLOW}$theme_name${NC}\n"
    
    # Create directory structure
    mkdir -p "$theme_dir"/{hypr,kitty,swaync,waybar,rofi,wlogout,hyprlock,polkit}
    
    # Create theme.conf
    cat > "$theme_dir/theme.conf" << EOF
# Theme Configuration
name="$theme_name"
description="Custom theme"
author="$(whoami)"
wallpaper=""

# Add custom variables here
# primary_color="#000000"
# secondary_color="#ffffff"
EOF
    
    echo -e "${GREEN}✓ Theme template created at: $theme_dir${NC}"
    echo -e "${YELLOW}Now add your theme files to the subdirectories${NC}\n"
}

save_current_as_theme() {
    local theme_name="$1"
    local theme_dir="$THEMES_DIR/$theme_name"
    
    if [ -d "$theme_dir" ]; then
        echo -e "${RED}✗ Theme '$theme_name' already exists!${NC}"
        read -p "Overwrite? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    echo -e "${BLUE}Saving current configuration as: ${YELLOW}$theme_name${NC}\n"
    
    # Create directory structure
    mkdir -p "$theme_dir"/{hypr,kitty,swaync,waybar,rofi,wlogout,hyprlock,polkit}
    
    # Copy current configs
    [ -f "$CONFIG_DIR/hypr/themes/current.conf" ] && cp "$CONFIG_DIR/hypr/themes/current.conf" "$theme_dir/hypr/theme.conf"
    [ -f "$CONFIG_DIR/kitty/current-theme.conf" ] && cp "$CONFIG_DIR/kitty/current-theme.conf" "$theme_dir/kitty/theme.conf"
    [ -f "$CONFIG_DIR/swaync/style.css" ] && cp "$CONFIG_DIR/swaync/style.css" "$theme_dir/swaync/"
    [ -f "$CONFIG_DIR/swaync/config.json" ] && cp "$CONFIG_DIR/swaync/config.json" "$theme_dir/swaync/"
    [ -f "$CONFIG_DIR/waybar/style.css" ] && cp "$CONFIG_DIR/waybar/style.css" "$theme_dir/waybar/"
    [ -f "$CONFIG_DIR/waybar/config.jsonc" ] && cp "$CONFIG_DIR/waybar/config.jsonc" "$theme_dir/waybar/"
    [ -f "$CONFIG_DIR/rofi/colors.rasi" ] && cp "$CONFIG_DIR/rofi/colors.rasi" "$theme_dir/rofi/"
    [ -f "$CONFIG_DIR/wlogout/style.css" ] && cp "$CONFIG_DIR/wlogout/style.css" "$theme_dir/wlogout/"
    [ -f "$CONFIG_DIR/wlogout/layout" ] && cp "$CONFIG_DIR/wlogout/layout" "$theme_dir/wlogout/"
    [ -f "$CONFIG_DIR/hypr/hyprlock.conf" ] && cp "$CONFIG_DIR/hypr/hyprlock.conf" "$theme_dir/hyprlock/"
    
    # Get current wallpaper
    current_wallpaper=$(grep "^wallpaper = " "$CONFIG_DIR/waypaper/config.ini" | cut -d'=' -f2 | xargs)
    
    # Create theme.conf
    cat > "$theme_dir/theme.conf" << EOF
# Theme Configuration
name="$theme_name"
description="Saved from current configuration"
author="$(whoami)"
wallpaper="$current_wallpaper"
EOF
    
    echo -e "${GREEN}✓ Current configuration saved as theme '$theme_name'${NC}\n"
}

show_usage() {
    echo "Usage: $(basename "$0") [OPTION] [THEME_NAME]"
    echo ""
    echo "Options:"
    echo "  -l, --list              List all available themes"
    echo "  -a, --apply THEME       Apply a theme"
    echo "  -s, --save THEME        Save current config as a new theme"
    echo "  -n, --new THEME         Create a new empty theme template"
    echo "  -c, --current           Show currently active theme"
    echo "  --cycle                 Cycle to next theme"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Interactive mode (no arguments):"
    echo "  Run without arguments for an interactive menu"
    echo ""
}

interactive_mode() {
    print_banner
    
    current=$(get_current_theme)
    echo -e "${BLUE}Current theme:${NC} ${YELLOW}$current${NC}\n"
    
    list_themes
    
    read -p "Select theme number (or 'q' to quit): " choice
    
    if [[ "$choice" == "q" ]] || [[ "$choice" == "Q" ]]; then
        echo "Bye!"
        exit 0
    fi
    
    # Get theme name by number
    local i=1
    for theme in "$THEMES_DIR"/*/ ; do
        if [ -d "$theme" ]; then
            if [ "$i" -eq "$choice" ]; then
                theme_name=$(basename "$theme")
                apply_theme "$theme_name"
                exit 0
            fi
            ((i++))
        fi
    done
    
    echo -e "${RED}✗ Invalid selection${NC}"
    exit 1
}

cycle_theme() {
    local current=$(get_current_theme)
    local themes_array=()
    
    # Build array of available themes
    for theme in "$THEMES_DIR"/*/ ; do
        if [ -d "$theme" ]; then
            themes_array+=("$(basename "$theme")")
        fi
    done
    
    if [ ${#themes_array[@]} -eq 0 ]; then
        echo -e "${RED}✗ No themes found${NC}"
        exit 1
    fi
    
    # Find current theme index
    local found=0
    local next_theme=""
    
    for i in "${!themes_array[@]}"; do
        if [ "$found" -eq 1 ]; then
            next_theme="${themes_array[$i]}"
            break
        fi
        if [ "${themes_array[$i]}" = "$current" ]; then
            found=1
        fi
    done
    
    # If we're at the last theme or theme not found, cycle to first
    if [ -z "$next_theme" ]; then
        next_theme="${themes_array[0]}"
    fi
    
    print_banner
    apply_theme "$next_theme"
}

# ============================================================================
# Main
# ============================================================================

# Create themes directory if it doesn't exist
mkdir -p "$THEMES_DIR"

# Parse arguments
case "${1:-}" in
    -l|--list)
        print_banner
        current=$(get_current_theme)
        echo -e "${BLUE}Current theme:${NC} ${YELLOW}$current${NC}\n"
        list_themes
        ;;
    -a|--apply)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}✗ Please specify a theme name${NC}"
            exit 1
        fi
        print_banner
        apply_theme "$2"
        ;;
    -s|--save)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}✗ Please specify a theme name${NC}"
            exit 1
        fi
        print_banner
        save_current_as_theme "$2"
        ;;
    -n|--new)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}✗ Please specify a theme name${NC}"
            exit 1
        fi
        print_banner
        create_theme_template "$2"
        ;;
    -c|--current)
        print_banner
        current=$(get_current_theme)
        echo -e "${BLUE}Current theme:${NC} ${YELLOW}$current${NC}\n"
        ;;
    --cycle)
        cycle_theme
        ;;
    -h|--help)
        print_banner
        show_usage
        ;;
    "")
        # No arguments - interactive mode
        interactive_mode
        ;;
    *)
        echo -e "${RED}✗ Unknown option: $1${NC}\n"
        show_usage
        exit 1
        ;;
esac
