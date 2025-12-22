#!/usr/bin/env bash

# Function to handle monitor events
handle_monitors() {
    # Get list of connected monitors
    monitors_json=$(hyprctl monitors -j)
    
    # Check for specific monitors
    dp1_connected=$(echo "$monitors_json" | jq -e 'map(select(.name == "DP-1")) | length > 0')
    dp2_connected=$(echo "$monitors_json" | jq -e 'map(select(.name == "DP-2")) | length > 0')
    
    if [[ "$dp1_connected" == "true" ]] && [[ "$dp2_connected" == "true" ]]; then
        # Desktop Mode
        echo "Detected Desktop Dual Monitors. Applying settings..."
        
        # Configure Monitors
        hyprctl keyword monitor "DP-1, 2560x1440@165, 0x0, 1"
        hyprctl keyword monitor "DP-2, 2560x1440@165, 2560x0, 1"
        
        # Bind Workspaces to Monitors
        hyprctl keyword workspace "1, monitor:DP-1, default:true"
        hyprctl keyword workspace "2, monitor:DP-1"
        hyprctl keyword workspace "3, monitor:DP-1"
        hyprctl keyword workspace "4, monitor:DP-1"
        hyprctl keyword workspace "5, monitor:DP-1"
        
        hyprctl keyword workspace "6, monitor:DP-2, default:true"
        hyprctl keyword workspace "7, monitor:DP-2"
        hyprctl keyword workspace "8, monitor:DP-2"
        hyprctl keyword workspace "9, monitor:DP-2"
        hyprctl keyword workspace "10, monitor:DP-2"
        
        # Optional: Disable laptop screen if desired, or leave as extra
        # hyprctl keyword monitor "eDP-1, disable"
        
    else
        # Laptop/Single Monitor Mode
        echo "Detected Laptop/Single Monitor. Applying settings..."
        
        # Configure Laptop Monitor matches user request: 1920x1200@60 1.25x
        # Note: If monitors are disconnected, Hyprland handles fallbacks automatically for workspace visibility,
        # but we enforce the preference here.
        hyprctl keyword monitor "eDP-1, 1920x1200@60, 0x0, 1.25"
        
        # Rebind workspaces to eDP-1 (or whatever is active)
        # We unbind strict monitor rules by setting them to the active monitor or just eDP-1
        hyprctl keyword workspace "1, monitor:eDP-1, default:true"
        hyprctl keyword workspace "2, monitor:eDP-1"
        hyprctl keyword workspace "3, monitor:eDP-1"
        hyprctl keyword workspace "4, monitor:eDP-1"
        hyprctl keyword workspace "5, monitor:eDP-1"
        hyprctl keyword workspace "6, monitor:eDP-1"
        hyprctl keyword workspace "7, monitor:eDP-1"
        hyprctl keyword workspace "8, monitor:eDP-1"
        hyprctl keyword workspace "9, monitor:eDP-1"
        hyprctl keyword workspace "10, monitor:eDP-1"
    fi
}

# Initial run
handle_monitors

# Listen for monitor events
socat - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do
    if [[ "$line" == "monitoradded>>"* ]] || [[ "$line" == "monitorremoved>>"* ]]; then
        handle_monitors
    fi
done
