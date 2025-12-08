#!/usr/bin/env bash

source "$PLUGIN_DIR/aerospace/map_monitors.sh"

# Invisible watcher that stores the current connected displays state in its label.
# Create the invisible item and attach the plugin script and cache the result
# TODO: There's actually no NSDistributedNotificationCenter notification for monitor changes, this is  all moot
sketchybar --add item DISPLAY_CHANGE right \
    --set DISPLAY_CHANGE script="$PLUGIN_DIR/aerospace/display_changes.sh" display=0 updates=on label="$(map_monitors)" \
    --add event display_changed \
    --subscribe DISPLAY_CHANGE display_changed

# reads the cached result from the above invisible item
read -a AS_TO_SB <<<"$(sketchybar --query DISPLAY_CHANGE | jq -r '.label.value')"
AEROSPACE_FOCUSED_WS=$(aerospace list-workspaces --focused)

args=()
args+=(--add event aerospace_workspace_change)
args+=(--add event aerospace_focus_change)
args+=(--add event aerospace_monitor_move)
ALL_AS_WS_AS_MON=$(aerospace list-workspaces --all --format '%{workspace} %{monitor-id}')
while read -r i as_monitor; do
    sb_monitor=${AS_TO_SB[(($as_monitor - 1))]}
    sid=$i
    if [ $sid = $AEROSPACE_FOCUSED_WS ]; then
        SID_BORDER_COLOR=0xff9ed072
        SID_ICON_HIGHLIGHT="true"
        SID_LABEL_HIGHLIGHT="true"
    else
        SID_BORDER_COLOR=0xff363944
        SID_ICON_HIGHLIGHT="false"
        SID_LABEL_HIGHLIGHT="false"
    fi
    space=(
        space="space.$sid"
        icon="$sid"
        icon.padding_left=7
        icon.padding_right=0
        icon.color=0xffffffff
        icon.highlight=0xffffffff
        background.color=0x40ffffff
        background.corner_radius=5
        background.height=25
        background.drawing=off
        background.border_color=0xffffffff
        click_script="aerospace workspace $sid"
    )
    args+=(--add space space.$sid left)

    apps=$(aerospace list-windows --workspace "$sid" </dev/null | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')

    echo "space $sid on monitor $sb_monitor"

    args+=(
        --set space.$sid "${space[@]}"
        display="$sb_monitor"
    )

    # I don't know what this is doing???
    # for i in $(aerospace list-workspaces --monitor "$as_monitor" --empty </dev/null); do
    #   args+=(--set space.$sid display=0)
    # done

done <<<"${ALL_AS_WS_AS_MON}"

# set up "workspace changer" item to receive events and update the spaces
args+=(--add item as_ws_changer left)
args+=(--set as_ws_changer drawing=off updates=on script="$PLUGIN_DIR/aerospace/refresh_space_indicators.sh")
args+=(--subscribe as_ws_changer aerospace_workspace_change)
args+=(--subscribe as_ws_changer aerospace_focus_change)
args+=(--subscribe as_ws_changer aerospace_monitor_move)

if [ ${#args[@]} -gt 0 ]; then
    sketchybar "${args[@]}"
fi
