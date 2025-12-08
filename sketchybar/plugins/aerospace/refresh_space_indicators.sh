#!/usr/bin/env bash

# AS = aerospace

read -a AS_TO_SB <<<"$(sketchybar --query DISPLAY_CHANGE | jq -r '.label.value')"

reload_workspace_icon() {
  local outvar=$1 # args to pass through to sketchybar command
  local args_=() # args to inject into sketchybar command

  # $1 - args to pass through
  # $2 - aerospace workspace to modify
  # $3 - aerospace monitor now holding workspace
  # $4 - whether to mark the workspace as focused
  # $5 - whether to hide the workspace
  echo "args $1 ws_to_modify $2 target_monitor $3 is_focused $4 should_hide $5"

  # decide on styling for the targeted workspace
  if [ "$4" = 1 ]; then
    # focused workspace styling
    BACKGROUND_DRAWING="on"
    # AS_TO_SB is zero-based, but as_monitor is one-based
    SID_DISPLAY=${AS_TO_SB[(($3 - 1))]}
  else
    BACKGROUND_DRAWING="off"
  fi

  # handle whether to disappear the workspace or not
  if [ $5 = 1 ]; then
    SID_DISPLAY=0
  else
    # AS_TO_SB is zero-based, but as_monitor is one-based
    SID_DISPLAY=${AS_TO_SB[(($3 - 1))]}
  fi

  args_+=(--set space.$2
    display="$SID_DISPLAY"
    label="$sid"
    background.drawing="$BACKGROUND_DRAWING"
  )

  eval "$outvar+=(\"\${args_[@]}\")"
}

ALL_APPS=$(aerospace list-windows --all --format '%{workspace} %{workspace-is-focused} %{app-name}') # needed to determine which workspaces are empty
ALL_AS_WS=$(aerospace list-workspaces --all --format '%{workspace} %{workspace-is-focused} %{workspace-is-visible} %{monitor-id}')

# this one seems to work correctly
if [ "$SENDER" = "aerospace_monitor_move" ]; then
  while IFS=" " read -r sid is_focused is_visible as_monitor; do
    if [ "$is_focused" = "true" ]; then
      AS_FOCUSED_MONITOR=$as_monitor
      AS_FOCUSED_WS=$sid
    fi
  done <<<"${ALL_AS_WS}"

  args=()
  reload_workspace_icon args $AS_FOCUSED_WS $AS_FOCUSED_MONITOR 1 0

  if [ ${#args[@]} -gt 0 ]; then
    sketchybar "${args[@]}"
  fi
fi

# this one does not
if [ "$SENDER" = "aerospace_workspace_change" ]; then
  echo "aerospace_workspace_change, previous workspace $PREV_WORKSPACE focused workspace $FOCUSED_WORKSPACE"
  AS_NONEMPTY_WS=""
  while read -r sid ws_is_focused app_names; do
    AS_NONEMPTY_WS+="$sid"$'\n'
  done <<<"${ALL_APPS}"
  AS_NONEMPTY_WS=" ${AS_NONEMPTY_WS//$'\n'/ }"

  AS_EMPTY_WS=""
  while IFS=" " read -r sid is_focused is_visible as_monitor; do
    if [ "$sid" = "$PREV_WORKSPACE" ]; then
      AS_PREV_MONITOR=$as_monitor
    fi

    if [ "$is_focused" = "true" ]; then
      AS_FOCUSED_MONITOR=$as_monitor
    fi

    if [[ ! " $AS_NONEMPTY_WS " == *" $sid "* ]]; then
      AS_EMPTY_WS+="$sid"$'\n'
    fi
  done <<<"${ALL_AS_WS}"

  args=()

  AS_PREV_WS_IS_EMPTY=0
  for i in $AS_EMPTY_WS; do
    if [ "$i" = "$AS_FOCUSED_WS" ]; then
      continue
    fi
    if [ "$i" = "$PREV_WORKSPACE" ]; then
      AS_PREV_WS_IS_EMPTY=1
    fi
    echo "hide workspace $i due to emptiness"
    args+=(--set space.$i display=0)
  done
  reload_workspace_icon args $PREV_WORKSPACE $AS_PREV_MONITOR 0 $AS_PREV_WS_IS_EMPTY
  reload_workspace_icon args $FOCUSED_WORKSPACE $AS_FOCUSED_MONITOR 1 0
  if [ ${#args[@]} -gt 0 ]; then
    sketchybar "${args[@]}"
  fi
fi
  echo "aerospace_monitor_move"


