#!/bin/bash

battery=(
  script="$PLUGIN_DIR/battery.sh"
  icon.font="$FONT:Regular:19.0"
  label.drawing=on
  padding_right=5
  padding_left=0
  update_freq=120
  updates=on
)

sketchybar --add item battery right      \
           --set battery "${battery[@]}" \
           --subscribe battery power_source_change system_woke
