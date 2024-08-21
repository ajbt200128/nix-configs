{ pkgs, ... }:
let pkgsWithEmacsPatches = pkgs.extend (import ./emacs.nix);
in let pkgs = pkgsWithEmacsPatches;
in {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    htop
    ripgrep
    sketchybar
    skhd
    vim
    emacs
    yabai
  ];
  environment.pathsToLink = [ "/share/zsh" ];
  fonts.packages = with pkgs; [ fira-code source-code-pro ];

  homebrew = {
    enable = true;
    brews = [
      {
        name = "semgrep/infra/libxmlsec1@1.2.37";
        link = true;
        conflicts_with = [ "libxmlsec1" ];
      }
      "emscripten"
    ];
    caskArgs.appdir = "~/Applications";
    casks = [
      "mactex"
      "dmenu-mac"
      "kap"
      "sf-symbols"
      "font-iosevka-nerd-font"
      "font-hack-nerd-font"
    ];
    taps = [{
      name = "semgrep/infra";
      clone_target = "git@github.com:semgrep/homebrew-infra.git";
    }];
  };
  services = {
    # Auto upgrade nix package and the daemon service.
    nix-daemon.enable = true;
    emacs = {
      enable = true;
      package = pkgs.emacs;
    };
    # Tiling WM for macOS
    yabai = {
      enable = true;
      enableScriptingAddition = true;
      extraConfig = (builtins.readFile ./yabairc);
    };
    # Hotkey daemon for yabai
    skhd = {
      enable = true;
      skhdConfig = ''
        # emacs
        cmd - e : ${pkgs.emacs}/bin/emacsclient -c -s $(lsof -c emacs | grep emacs$UID/server | grep -E -o '[^[:blank:]]*$')
      '' + (builtins.readFile ./skhdrc);
    };
    # Status bar for macOS
    sketchybar = {
      enable = true;
      config = ''
        PLUGIN_DIR=${./sketchybar/plugins}
      '' + (builtins.readFile ./sketchybarrc);
    };
  };
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;
  system.defaults = {
    dock = {
      # TODO: persistent-apps
      autohide = true;
      show-recents = false;
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs = {
    hostPlatform = "aarch64-darwin";
    config.allowUnfree = true;
  };
}
