#!/bin/bash
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export LC_ALL=C
CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"

# Fixed widths prevent titles and percentages from displacing essential items.
display_width() {
  local width
  width=$(sketchybar --query displays | jq -r '[.[].frame.w] | min // 1024 | floor' 2>/dev/null)
  case "$width" in ''|*[!0-9]*) width=1024 ;; esac
  printf '%s\n' "$width"
}

metric() {
  local name="$1" value="$2" warn="$3" critical="$4" color="$TEXT" style=Medium label
  case "$value" in
    ''|*[!0-9]*) label=--; color="$ERROR"; style=Bold ;;
    *) label="${value}%"
       if [ "$value" -ge "$critical" ]; then color="$RED"; style=Bold
       elif [ "$value" -ge "$warn" ]; then color="$WARNING"; fi ;;
  esac
  # A previous sampler can finish while a reload replaces its items.
  sketchybar --query "$name" >/dev/null 2>&1 || return 0
  sketchybar --set "/^${name}$/" label="$label" label.color="$color" label.font.style="$style"
}

case "$1" in
  workspace)
    case "$2" in [1-4]) ;; *) exit 1 ;; esac
    focused="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"
    if [ "$focused" = "$2" ]; then
      sketchybar --set "space.$2" icon.color="$BACKGROUND" background.drawing=on icon.background.drawing=on
    else
      sketchybar --set "space.$2" icon.color="$SECONDARY" background.drawing=off icon.background.drawing=off
    fi
    ;;
  frontapp)
    window=$(aerospace list-windows --focused --json 2>/dev/null)
    # shortcut: SketchyBar query JSON does not escape quotes or backslashes; remove when fixed upstream.
    app=$(printf '%s' "$window" | jq -r '
      .[0] |
      (."app-name" // "Desktop" | if . == "" then "Desktop" else . end) as $app |
      (."window-title" // "") as $title |
      (if $title == "" then $app else "\($app) - “\($title)”" end) |
      gsub("[[:cntrl:]]"; " ") | gsub("\""; "″") | gsub("\\\\"; "∖") |
      if length>64 then .[:61]+"..." else . end' 2>/dev/null)
    sketchybar --set '/^frontapp$/' icon="${app:-Desktop}"
    ;;
  clock)
    sketchybar --set clock label="$(date '+%-I:%M %p')"
    ;;
  battery)
    battery=$(pmset -g batt 2>/dev/null)
    percent=$(printf '%s\n' "$battery" | grep -Eo '[0-9]+%' | head -1 | tr -d '%')
    icon=BAT; color="$TEXT"; style=Medium
    case "$battery" in *'AC Power'*) icon=AC ;; esac
    if [ -z "$percent" ]; then
      label=--; color="$ERROR"; style=Bold
    else
      if [ "$percent" -lt 20 ]; then color="$RED"; style=Bold; fi
      label="${percent}%"
    fi
    sketchybar --set battery drawing=on width=68 icon="$icon" icon.width=24 icon.align=center icon.padding_left=0 \
      label="$label" label.color="$color" label.font.style="$style"
    ;;
  volume)
    value="${INFO:-}"
    if [ "${SENDER:-}" != volume_change ]; then
      value=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)
    fi
    case "$value" in ''|*[!0-9]*) metric volume '' 101 101 ;;
      *) metric volume "$value" 101 101 ;; esac
    ;;
  vpn)
    drawing=off
    # Existing utun devices alone do not mean a VPN is connected.
    if scutil --nc list 2>/dev/null | grep -q '(Connected)' ||
       scutil --nwi 2>/dev/null | awk '/^Network interfaces:/ {for (i=3; i<=NF; i++) if ($i ~ /^(utun|ppp|ipsec)[0-9]+$/) active=1} END {exit !active}'; then
      drawing=on
    fi
    sketchybar --set vpn drawing="$drawing"
    ;;
  stats)
    # The first iostat row is the boot average; use the second, one-second sample.
    cpu=$(iostat -C -n 0 -c 2 -w 1 2>/dev/null | awk '
      NF == 6 && $1 ~ /^[0-9]+$/ {idle=$3; samples++}
      END {if (samples>=2 && idle ~ /^[0-9]+$/ && idle<=100) printf "%.0f", 100-idle}')
    total=$(sysctl -n hw.memsize 2>/dev/null)
    memory=$(vm_stat 2>/dev/null | awk -v total="$total" '
      /page size of/ {size=$8}
      /Pages active:|Pages wired down:|Pages occupied by compressor:/ {pages+=$NF}
      END {if (total>0 && size>0) {used=100*pages*size/total; printf "%.0f", (used>100 ? 100 : used)}}')
    metric cpu "$cpu" 91 91
    metric memory "$memory" 91 91
    case "$cpu" in
      ''|*[!0-9]*) ;;
      *) sample=$(awk -v cpu="$cpu" 'BEGIN {printf "%.2f", cpu/100}')
         if sketchybar --query cpu >/dev/null 2>&1; then sketchybar --push cpu "$sample"; fi ;;
    esac
    ;;
  memory)
    # CPU polling samples both metrics; this item has no separate timer.
    ;;
  media)
    data=$(media-control get --no-artwork --allow-missing-title 2>/dev/null)
    title=$(printf '%s' "$data" | jq -r 'select(.playing == true) | (.title // "Audio") | if . == "" then "Audio" else . end | gsub("[[:cntrl:]]"; " ") | if length>14 then .[:11]+"..." else . end' 2>/dev/null)
    drawing=off
    if [ -n "$title" ] && [ "$(display_width)" -ge 1600 ]; then drawing=on; fi
    sketchybar --set media label="$title" drawing="$drawing" \
      --set media.pause drawing="$drawing" --set media.skip drawing="$drawing"
    ;;
  media-action)
    case "$2" in pause|next-track) ;; *) exit 1 ;; esac
    media-control "$2" >/dev/null || exit 1
    sketchybar --trigger media_refresh
    ;;
  layout)
    width=$(display_width)
    app_width=520; max_chars=64
    [ "$width" -ge 1600 ] || { app_width=260; max_chars=32; }
    media=off; stats=on; volume=on
    if [ "$width" -lt 1100 ]; then app_width=160; max_chars=20; fi
    if [ "$width" -lt 900 ]; then app_width=128; max_chars=16; fi
    [ "$width" -ge 1120 ] || stats=off
    [ "$width" -ge 1280 ] || volume=off
    if [ "$width" -ge 1600 ]; then
      title=$(sketchybar --query media | jq -r '.label.value // ""' 2>/dev/null)
      [ -z "$title" ] || media=on
    fi
    sketchybar --set '/^frontapp$/' width="$app_width" icon.width="$app_width" icon.max_chars="$max_chars" \
      --set cpu drawing="$stats" --set memory drawing="$stats" \
      --set volume drawing="$volume" --set media drawing="$media" \
      --set media.pause drawing="$media" --set media.skip drawing="$media"
    ;;
  *) exit 1 ;;
esac
