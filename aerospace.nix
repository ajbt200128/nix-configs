let
  trigger_aerospace_workspace_change = "sketchybar --trigger aerospace_workspace_change FOCUSED=$AEROSPACE_FOCUSED_WORKSPACE PREV_WORKSPACE=$AEROSPACE_PREV_WORKSPACE";
  make_mv_workspace = ws: [
    "move-node-to-workspace --focus-follows-window ${toString ws}"
    "exec-and-forget ${trigger_aerospace_workspace_change}"
  ];
in
{
  default-root-container-layout = "tiles";
  gaps = {
    outer.left = 8;
    outer.right = 8;
    outer.top = 8;
    outer.bottom = 8;
    inner.horizontal = 5;
    inner.vertical = 5;
  };

  exec.env-vars = {
    PATH = "/opt/homebrew/bin:/run/current-system/sw/bin:/etc/profiles/per-user/r2cuser/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:";
  };

  after-startup-command = [
    "exec-and-forget sketchybar --reload"
  ];

  exec-on-workspace-change = [
    "/bin/bash"
    "-c"
    trigger_aerospace_workspace_change
  ];

  on-focused-monitor-changed = [
    "exec-and-forget sketchybar --trigger aerospace_focus_change"
  ];

  enable-normalization-flatten-containers = false; # more like i3
  enable-normalization-opposite-orientation-for-nested-containers = true;

  mode.main.binding = {
    cmd-h = "focus left";
    cmd-l = "focus right";
    cmd-j = "focus down";
    cmd-k = "focus up";

    cmd-shift-h = "swap left";
    cmd-shift-l = "swap right";
    cmd-shift-j = "swap down";
    cmd-shift-k = "swap up";

    cmd-1 = "workspace 1";
    cmd-2 = "workspace 2";
    cmd-3 = "workspace 3";
    cmd-4 = "workspace 4";
    cmd-5 = "workspace 5";
    cmd-6 = "workspace 6";
    cmd-7 = "workspace 7";
    cmd-8 = "workspace 8";
    cmd-9 = "workspace 9";

    cmd-shift-1 = make_mv_workspace 1;
    cmd-shift-2 = make_mv_workspace 2;
    cmd-shift-3 = make_mv_workspace 3;
    cmd-shift-4 = make_mv_workspace 4;
    cmd-shift-5 = make_mv_workspace 5;
    cmd-shift-6 = make_mv_workspace 6;
    cmd-shift-7 = make_mv_workspace 7;
    cmd-shift-8 = make_mv_workspace 8;
    cmd-shift-9 = make_mv_workspace 9;

    cmd-shift-space = "layout floating tiling";

    cmd-shift-q = "close";

    cmd-shift-f = "macos-native-fullscreen";

    cmd-shift-r = "exec-and-forget launchctl kickstart -k gui/502/org.nixos.aerospace; sketchybar --reload";

    cmd-shift-0 = "exec-and-forget pmset display sleepnow";

    cmd-t = "exec-and-forget kitty -1";

    cmd-g = "exec-and-forget open -n -a \"Google Chrome\"";

    cmd-m = "exec-and-forget open -n -a \"Slack\"";

    cmd-d = "exec-and-forget dmenu-mac";

    cmd-p = "exec-and-forget open -n -a \"Screenshot\"";

    cmd-r = "exec-and-forget open -n -a \"Kap\"";

    cmd-e = "exec-and-forget emacsclient -c -s $(lsof -c emacs | grep emacs$UID/server | grep -E -o '[^[:blank:]]*$' | head -n 1)";

    cmd-shift-semicolon = "mode service";
  };

  workspace-to-monitor-force-assignment = {
    "1" = [ "built-in" ];
    "2" = [ "built-in" ];
    "3" = [ "built-in" ];
    "4" = [ "built-in" ];
    "5" = [
      "secondary"
      "built-in"
    ];
    "6" = [
      "secondary"
      "built-in"
    ];
    "7" = [
      "secondary"
      "built-in"
    ];
    "8" = [
      "3"
      "secondary"
      "built-in"
    ];
    "9" = [
      "3"
      "secondary"
      "built-in"
    ];
  };
}
