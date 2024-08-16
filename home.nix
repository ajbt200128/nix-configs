{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home = {
    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "24.05";

    # TODO sort by category
    packages = with pkgs;
      [
        asciinema
        aspell
        autoconf
        awscli2
        baobab
        bat
        binutils
        black
        cachix
        cmake
        curl
        delta
        direnv
        docker
        docker-compose
        emscripten
        fd
        ffmpeg
        fzf
        gawk
        gh
        git-lfs
        gnumake
        gnused
        gnutar
        graphviz
        grpcurl
        jq
        jsonnet
        kitty
        kubectl
        kustomize
        libev
        lsd
        nix-direnv
        nodejs
        nixfmt
        ocaml
        oh-my-zsh
        okta-aws-cli
        opam
        pcre
        pipx
        pkg-config
        poetry
        postgresql_15_jit
        pre-commit
        protobuf
        pyright
        rustup
        shellcheck
        shfmt
        speedtest-go
        spotify
        starship
        terraform
        tree-sitter
        vsce
        vscode
        wget
        yaml-language-server
        yarn
        yq-go
        zsh-autosuggestions
        zsh-syntax-highlighting
      ] ++ (with pkgs.nodePackages; [ eslint typescript-language-server ]);
  };
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      envExtra = (builtins.readFile ./zshenv);
      autosuggestion.enable = true;

      shellAliases = {
        ls = "${pkgs.lsd}/bin/lsd";
        et =
          "TERM=xterm ${pkgs.emacs}/bin/emacsclient -nw -s $(lsof -c emacs | grep emacs$UID/server | grep -E -o '[^[:blank:]]*$')";
        icat = "kitty +kitten icat";
        ssh = "kitty +kitten ssh";
        rebuild = "darwin-rebuild switch --flake $HOME/nix-darwin";
      };
      oh-my-zsh = {
        enable = true;

        plugins = [
          "git"
          "colored-man-pages"
          "command-not-found"
          "docker"
          "npm"
          "pep8"
          "pip"
          "python"
          "sudo"
          "fzf"
        ];
      };
      initExtra = ''
        function rgd() {
          ${pkgs.ripgrep}/bin/rg --json -C 2 "$@" | ${pkgs.delta}/bin/delta
        }
        function login-aws() {
          ${pkgs.awscli2}/bin/aws sso login --sso-session semgrep
          ${pkgs.awscli2}/bin/aws ecr get-login-password | ${pkgs.docker}/bin/docker login --username AWS --password-stdin 338683922796.dkr.ecr.us-west-2.amazonaws.com
        }
        if [[ -z "$\{SEMGREP_NIX_BUILD-\}" ]]; then
          eval $(opam env)
        fi
        # check if cwd = /
        if [ "$PWD" = "/" ]; then
          cd ~
        fi
      '';
      profileExtra = ''eval "$(/opt/homebrew/bin/brew shellenv)"'';
    };
    starship = {
      enable = true;
      enableZshIntegration = true;
      settings = builtins.fromTOML (builtins.readFile ./starship.toml);
    };
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    kitty = {
      enable = true;
      extraConfig = (builtins.readFile ./kitty.conf);
      shellIntegration.enableZshIntegration = true;
    };
  };
}
