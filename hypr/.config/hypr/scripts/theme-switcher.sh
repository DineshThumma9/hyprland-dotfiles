#!/bin/bash

# Hyprland Theme Switcher
# Switches between different color themes for Hyprland

THEME_DIR="$HOME/.config/hypr/themes"
CURRENT_THEME="$THEME_DIR/current.conf"
STATE_FILE="$HOME/.config/hypr/.current_theme"

# Available themes (without .conf extension)
THEMES=(
    "catppuccin-mocha"
    "gruvbox-dark"
    "nord"
    "tokyo-night"
    "dracula"
)

# Theme display names
declare -A THEME_NAMES=(
    ["catppuccin-mocha"]="Catppuccin Mocha"
    ["gruvbox-dark"]="Gruvbox Dark"
    ["nord"]="Nord"
    ["tokyo-night"]="Tokyo Night"
    ["dracula"]="Dracula"
)

# Function to get current theme
get_current_theme() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "catppuccin-mocha"
    fi
}

# Function to apply a theme
apply_theme() {
    local theme=$1
    local theme_file="$THEME_DIR/${theme}.conf"
    
    if [ ! -f "$theme_file" ]; then
        echo "Error: Theme file not found: $theme_file"
        exit 1
    fi
    
    # Copy the selected theme to current.conf
    cp "$theme_file" "$CURRENT_THEME"
    
    # Save the current theme name
    echo "$theme" > "$STATE_FILE"
    
    # Reload Hyprland configuration
    hyprctl reload
    
    # Regenerate hyprlock configuration with new theme colors
    if [ -f "$HOME/.config/hypr/scripts/generate-hyprlock.sh" ]; then
        bash "$HOME/.config/hypr/scripts/generate-hyprlock.sh"
    fi
    
    echo "Theme changed to: ${THEME_NAMES[$theme]}"
    
    # Send notification if notify-send is available
    if command -v notify-send &> /dev/null; then
        notify-send "Theme Changed" "Applied ${THEME_NAMES[$theme]} theme" -t 2000
    fi
}

# Function to show theme menu using rofi
show_rofi_menu() {
    local current=$(get_current_theme)
    local options=""
    
    for theme in "${THEMES[@]}"; do
        if [ "$theme" = "$current" ]; then
            options="${options}● ${THEME_NAMES[$theme]}\n"
        else
            options="${options}  ${THEME_NAMES[$theme]}\n"
        fi
    done
    
    # Dynamically fetch the rofi theme from the central environment file
    source "$HOME/.config/rofi/theme.env"
    
    # Show rofi menu
    selected=$(echo -e "$options" | rofi -dmenu -i -p "Select Theme" -theme "$ROFI_THEME" -theme-str 'window {width: 400px;}')
    
    if [ -z "$selected" ]; then
        exit 0
    fi
    
    # Remove the bullet point and spaces
    selected=$(echo "$selected" | sed 's/^[● ]*//')
    
    # Find the theme key from the display name
    for theme in "${THEMES[@]}"; do
        if [ "${THEME_NAMES[$theme]}" = "$selected" ]; then
            apply_theme "$theme"
            exit 0
        fi
    done
}

# Function to cycle to next theme
cycle_theme() {
    local current=$(get_current_theme)
    local found=0
    local next_theme=""
    
    for i in "${!THEMES[@]}"; do
        if [ "$found" -eq 1 ]; then
            next_theme="${THEMES[$i]}"
            break
        fi
        if [ "${THEMES[$i]}" = "$current" ]; then
            found=1
        fi
    done
    
    # If we're at the last theme or theme not found, cycle to first
    if [ -z "$next_theme" ]; then
        next_theme="${THEMES[0]}"
    fi
    
    apply_theme "$next_theme"
}

# Main script logic
case "${1:-menu}" in
    menu)
        show_rofi_menu
        ;;
    cycle)
        cycle_theme
        ;;
    list)
        echo "Available themes:"
        current=$(get_current_theme)
        for theme in "${THEMES[@]}"; do
            if [ "$theme" = "$current" ]; then
                echo "  ● ${THEME_NAMES[$theme]} (current)"
            else
                echo "    ${THEME_NAMES[$theme]}"
            fi
        done
        ;;
    current)
        current=$(get_current_theme)
        echo "${THEME_NAMES[$current]}"
        ;;
    *)
        # Try to apply the theme directly if it exists
        if [[ " ${THEMES[@]} " =~ " ${1} " ]]; then
            apply_theme "$1"
        else
            echo "Usage: $0 [menu|cycle|list|current|<theme-name>]"
            echo ""
            echo "Options:"
            echo "  menu          - Show rofi menu to select theme (default)"
            echo "  cycle         - Cycle to next theme"
            echo "  list          - List all available themes"
            echo "  current       - Show current theme"
            echo "  <theme-name>  - Apply specific theme"
            echo ""
            echo "Available themes:"
            for theme in "${THEMES[@]}"; do
                echo "  - $theme"
            done
            exit 1
        fi
        ;;
esac
