{ pkgs, ... }:
let pkgsWithEmacsPatches = pkgs.extend (import ./emacs.nix);
in let pkgs = pkgsWithEmacsPatches;
in {
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment = {
    systemPackages = with pkgs; [
      emacs
      htop
      juicefs
      pkg-config
      ripgrep
      sketchybar
      skhd
      vim
      yabai
    ];
    pathsToLink = [ "/share/zsh" ];
  };
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
      "enchant"
    ];
    caskArgs.appdir = "~/Applications";
    casks = [
      "dmenu-mac"
      "font-hack-nerd-font"
      "font-iosevka-nerd-font"
      "kap"
      "macfuse"
      "mactex"
      "sf-symbols"
      "xquartz"
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
      skhdConfig = (builtins.readFile ./skhdrc);
    };
    # Status bar for macOS
    sketchybar = {
      enable = true;
      config = ''
        PLUGIN_DIR=${./sketchybar/plugins}
      '' + (builtins.readFile ./sketchybarrc);
    };
  };

  nix.settings = {
    # Necessary for using flakes on this system.
    experimental-features = "nix-command flakes";
    trusted-substituters = [ "r2cuser" ];
    substituters =
      [ "https://nix-community.cachix.org" "https://semgrep.cachix.org" ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "semgrep.cachix.org-1:waxSNb3ism0Vkmfa31//YYrOC2eMghZmTwy9bvMAGBI="
    ];
  };

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
