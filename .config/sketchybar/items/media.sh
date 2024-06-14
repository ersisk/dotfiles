media=(
  icon.background.drawing=on
  icon.background.image=media.artwork
  icon.background.image.corner_radius=9
  script="$PLUGIN_DIR/media.sh"
  label.max_chars=15
  scroll_texts=on
  updates=on
  icon.color=$GREEN
)

sketchybar --add item media right \
           --set media "${media[@]}" icon=󰝚 \
           --subscribe media media_change
