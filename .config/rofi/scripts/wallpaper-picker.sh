#!/bin/bash
WALLDIR="$HOME/Pictures/Wallpapers"
entries=""

# Build entries: each wallpaper file with icon metadata for Rofi grid display
for wp in "$WALLDIR"/*.{jpg,jpeg,png}; do
  fname=$(basename "$wp")
  entries="$entries$fname\x00icon\x1f$wp\n"
done

chosen=$(echo -e "$entries" | rofi \
  -dmenu \
  -theme ~/.config/rofi/themes/wallpaper-picker.rasi \
  -p "Pick Wallpaper")

if [[ -n "$chosen" ]]; then
  WALLPAPER="$WALLDIR/$chosen"
  # First, run matugen to generate color and theme configs for the selected wallpaper
  matugen image "$WALLPAPER"
  # Set wallpaper with swww (Hyprland Wayland utility, or use your own wallpaper setter)
  swww img "$WALLPAPER"
fi
