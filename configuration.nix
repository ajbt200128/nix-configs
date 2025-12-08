{ pkgs, ... }:
let
  pkgsWithEmacsPatches = pkgs.extend (import ./emacs.nix);
in
let
  pkgs = pkgsWithEmacsPatches;
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = with pkgs; [
      emacs
      enchant
      htop
      juicefs
      pkg-config
      ripgrep
      sketchybar
      skhd
      vim
    ];
    pathsToLink = [ "/share/zsh" ];
  };
  fonts.packages = with pkgs; [
    fira-code
    source-code-pro
  ];

  homebrew = {
    enable = true;
    brews = [ "depot" ];
    caskArgs.appdir = "~/Applications";
    casks = [
      "betterdisplay"
      "daisydisk"
      "dmenu-mac"
      "font-hack-nerd-font"
      "font-iosevka-nerd-font"
      "kap"
      "macfuse"
      "mactex"
      "sf-symbols"
      "vial"
      "xquartz"
    ];
  };
  services = {
    emacs = {
      enable = true;
      # use patched emacs for daemon
      package = pkgs.emacs;
    };
    aerospace = {
      enable = true;
      settings = ./aerospace.nix;
    };
    # Status bar for macOS
    sketchybar = {
      enable = true;
      config = ''
        PLUGIN_DIR=${./sketchybar/plugins}
        ITEMS_DIR=${./sketchybar/items}
      ''
      + (builtins.readFile ./sketchybarrc);
      extraPackages = with pkgs; [
        jq
      ];
    };

    jankyborders = {
      enable = true;
      # active color should be a nice pastel green
      active_color = "#7FBF7F";
      # inactive color should be a nice pastel gray
      inactive_color = "#707070";

      width = 3.0;
    };
  };

  nix.settings = {
    # Necessary for using flakes on this system.
    experimental-features = "nix-command flakes";
    extra-trusted-substituters = [ "r2cuser" ];
    trusted-users = [ "r2cuser" ];
    substituters = [
      "https://nix-community.cachix.org"
      "https://semgrep.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "semgrep.cachix.org-1:waxSNb3ism0Vkmfa31//YYrOC2eMghZmTwy9bvMAGBI="
    ];
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  system.primaryUser = "r2cuser"; # The primary user of the system.
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
