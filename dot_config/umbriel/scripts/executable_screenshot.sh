#!/usr/bin/env bash
set -euo pipefail
mkdir -p "$HOME/Pictures/Screenshots"
filepath="$HOME/Pictures/Screenshots/ss_$(date +%Y%m%d%H%M%S).png"

case "${1:-fullscreen}" in
region)
  g=$(slurp -d)
  [ -z "$g" ] && exit 1
  grim -g "$g" "$filepath"
  wl-copy --type image/png <"$filepath"
  notify-send -i "$filepath" "Screenshot (region)" "$filepath"
  ;;
window)
  g=$(mmsg get focusing-client | jq -r '"\(.x),\(.y) \(.width)x\(.height)"')
  [ -z "$g" ] && exit 1
  grim -g "$g" "$filepath"
  wl-copy --type image/png <"$filepath"
  notify-send -i "$filepath" "Screenshot (window)" "$filepath"
  ;;
freeze)
  p=$(mktemp -u).fifo
  mkfifo "$p"
  wayfreeze --after-freeze-timeout 100 --after-freeze-cmd "echo > $p" &
  wp=$!
  read -r <"$p"
  grim "$filepath"
  kill "$wp" 2>/dev/null
  rm -f "$p"
  wl-copy --type image/png <"$filepath"
  notify-send -i "$filepath" "Screenshot (frozen)" "$filepath"
  ;;
freeze-region)
  p=$(mktemp -u).fifo
  mkfifo "$p"
  wayfreeze --after-freeze-timeout 100 --after-freeze-cmd "echo > $p" &
  wp=$!
  read -r <"$p"
  g=$(slurp -d)
  if [ -z "$g" ]; then
    kill "$wp" 2>/dev/null
    rm -f "$p"
    exit 1
  fi
  grim -g "$g" "$filepath"
  kill "$wp" 2>/dev/null
  rm -f "$p"
  wl-copy --type image/png <"$filepath"
  notify-send -i "$filepath" "Screenshot (frozen region)" "$filepath"
  ;;
annotate)
  grim "$filepath"
  satty --filename "$filepath" --output-filename "$filepath" --disable-notifications --actions-on-enter save-to-file --early-exit
  wl-copy --type image/png <"$filepath"
  notify-send -i "$filepath" "Screenshot (annotated)" "$filepath"
  ;;
monitor)
  g=$(mmsg get all-monitors | jq -r '
    .monitors[] | select(.active == true)
    | "\(.x),\(.y) \(.width)x\(.height)"
  ')
  [ -z "$g" ] && exit 1
  grim -g "$g" "$filepath"
  wl-copy --type image/png <"$filepath"
  notify-send -i "$filepath" "Screenshot (monitor)" "$filepath"
  ;;
*)
  grim "$filepath"
  wl-copy --type image/png <"$filepath"
  notify-send -i "$filepath" "Screenshot" "$filepath"
  ;;
esac
