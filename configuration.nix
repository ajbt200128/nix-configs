{ pkgs, ... }: {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    htop
    ripgrep
    sketchybar
    skhd
    # needed for emacs
    tree-sitter
    vim
    yabai
  ];
  environment.pathsToLink = [ "/share/zsh" ];
  fonts.packages = with pkgs; [ fira-code source-code-pro ];

  homebrew = {
    enable = true;
    brews = [ ];
    caskArgs.appdir = "~/Applications";
    casks = [
      "dmenu-mac"
      "kap"
      "mactex"
      "sf-symbols"
      "font-iosevka-nerd-font"
      "font-hack-nerd-font"
    ];
  };
  services = {
    # Auto upgrade nix package and the daemon service.
    nix-daemon.enable = true;
    # Tiling WM for macOS
    yabai = {
      enable = true;
      enableScriptingAddition = true;
      extraConfig = (builtins.readFile ./yabairc);
    };
    # Hotkey daemon for yabai
    skhd = {
      enable = true;
      skhdConfig = (builtins.readFile ./skhdrc);
    };
    sketchybar = {
      enable = true;
      config = ''
        PLUGIN_DIR=${./sketchybar/plugins}
      '' + (builtins.readFile ./sketchybarrc);
    };
    emacs = {
      enable = true;
      package = "/opt/homebrew";
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
