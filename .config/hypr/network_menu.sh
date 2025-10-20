#!/usr/bin/env bash

# Network Menu Script for Hyprland using Rofi
# Dependencies: rofi, nmcli, notify-send, awk, grep

ROFI_CMD="rofi -dmenu -i -l 10 -p 'Network:'"
CONNECTION_EDITOR="nm-connection-editor" # GUI fallback for complex config

WIFI_ICON="" # FontAwesome Wi-Fi icon

# Function to get active network status
get_active_status() {
    # Get active connection name and SSID
    ACTIVE_CONN=$(nmcli -t -f active,name device show wlan0 2>/dev/null | grep '^yes' | cut -d ':' -f 2)
    ACTIVE_SSID=$(nmcli -t -f active,ssid device show wlan0 2>/dev/null | grep '^yes' | cut -d ':' -f 3)
    
    if [ -n "$ACTIVE_CONN" ]; then
        echo "$WIFI_ICON Connected: $ACTIVE_SSID (Disconnect)"
    else
        echo "$WIFI_ICON Disconnected (Scan & Connect)"
    fi
}

# Function to list available Wi-Fi networks
get_wifi_networks() {
    # nmcli -f BSSID,SSID,RATE,SIGNAL,BARS,SECURITY device wifi list --rescan yes | sed '1d'
    # Use a simpler list for Rofi:
    nmcli --fields NAME,SIGNAL,SECURITY device wifi list | tail -n +2 | awk '{
        ssid = $1; 
        signal = $2;
        security = $3;

        # Join SSIDs that have spaces
        for (i = 4; i <= NF; i++) {
            security = security " " $i;
        }

        # Select icon based on signal strength
        icon = "";
        if (signal > 80) icon = "";
        else if (signal > 60) icon = "";
        else if (signal > 40) icon = "";
        else icon = "";

        # Print formatted line: SSID | Signal | Security
        print icon " " ssid "\t(Sig: " signal "%)" "\t" security
    }' | sed 's/  */ /g' | sort -u
}

# Main menu logic
main_menu() {
    # Use the 'get_active_status' as the first, non-selectable menu option in Rofi
    STATUS_LINE=$(get_active_status)
    
    # Get the list of available networks
    NETWORK_LIST=$(get_wifi_networks)

    # Combine the status line and the network list, then display in Rofi
    MENU_OPTIONS=$(echo -e " Toggle Connection\n⚙️ Open Settings\nKEY Disconnect All\n$NETWORK_LIST")

    CHOSEN=$(echo -e "$MENU_OPTIONS" | $ROFI_CMD)

    # Check if a choice was made
    if [ -z "$CHOSEN" ]; then
        exit 0
    fi
    
    # Handle the selected option
    case "$CHOSEN" in
        " Toggle Connection")
            # If connected, disconnect. If disconnected, scan and connect.
            if [[ "$STATUS_LINE" == *"Connected"* ]]; then
                nmcli connection down "$ACTIVE_CONN"
                notify-send "$WIFI_ICON" "Disconnected from $ACTIVE_SSID."
            else
                # Rescan and show network list again
                notify-send "$WIFI_ICON" "Scanning for networks..."
                nmcli device wifi rescan
                sleep 2
                main_menu # Re-show menu with fresh networks
            fi
            ;;
        "⚙️ Open Settings")
            # Launch the official GUI tool for advanced configuration
            $CONNECTION_EDITOR &
            ;;
        "KEY Disconnect All")
            # Disconnect all active connections
            nmcli general disconnect
            notify-send "$WIFI_ICON" "All networks disconnected."
            ;;
        *)
            # This is a network connection attempt
            # Extract the SSID from the chosen line
            SSID=$(echo "$CHOSEN" | awk '{print $2}')
            
            # Check if it's already a known connection
            if nmcli connection show | grep -q "$SSID"; then
                # Connect to known network
                nmcli connection up "$SSID" iface wlan0
                notify-send "$WIFI_ICON" "Attempting to connect to $SSID..."
            else
                # New connection - will prompt for password if needed (usually through the NetworkManager agent)
                nmcli device wifi connect "$SSID"
                notify-send "$WIFI_ICON" "Attempting new connection to $SSID..."
            fi
            ;;
    esac
}

main_menu
