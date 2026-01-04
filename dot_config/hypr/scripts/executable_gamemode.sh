#!/usr/bin/env bash

# Check current animation state to determine if we are entering or exiting Game Mode
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

if [ "$HYPRGAMEMODE" = 1 ] ; then
    # =========================================================================
    # ENABLE GAME MODE
    # =========================================================================
    # 1. Disable animations (reduces latency)
    # 2. Disable shadows and blur (saves GPU resources)
    # 3. Remove gaps and rounding (maximizes screen usage)
    # =========================================================================
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword decoration:rounding 0"
    
    notify-send "Game Mode" "Enabled: Performance Optimized" -t 2000
    
else
    # =========================================================================
    # DISABLE GAME MODE (Restore defaults)
    # =========================================================================
    # Restores settings exactly as found in your provided hyprland.conf
    # =========================================================================
    hyprctl --batch "\
        keyword animations:enabled 1;\
        keyword decoration:shadow:enabled 1;\
        keyword decoration:blur:enabled 1;\
        keyword general:gaps_in 5;\
        keyword general:gaps_out 5;\
        keyword decoration:rounding 12"
        
    notify-send "Game Mode" "Disabled: Visuals Restored" -t 2000
fi
