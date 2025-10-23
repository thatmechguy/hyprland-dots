#!/bin/bash

CURRENT_PROFILE=$(powerprofilesctl get)

if [ "$CURRENT_PROFILE" == "performance" ]; then
    # If currently 'performance', switch to 'balanced'
    powerprofilesctl set balanced
    # Optional: notify-send "Power Profile" "Set to Balanced"
else
    # If currently 'balanced' (or anything else), switch to 'performance'
    powerprofilesctl set performance
    # Optional: notify-send "Power Profile" "Set to Performance"
fi
