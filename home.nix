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

    # services.aerospace is disabled (see configuration.nix); aerospace is
    # installed imperatively from jperras's PR 2036 fork via brew
    # install-from-sources to fix the emacs child-frame focus-jump bug.
    # We still render the config declaratively from ./aerospace.nix.
    file.".config/aerospace/aerospace.toml".source =
      (pkgs.formats.toml { }).generate "aerospace.toml" (import ./aerospace.nix);

    # TODO sort by category
    packages = with pkgs; [
      asciinema
      asciinema-agg
      awscli2
      bat
      black
      btop
      cachix
      ckc
      cmake
      curl
      delta
      devenv
      direnv
      docker
      docker-compose
      docker-buildx
      dos2unix
      emacs-lsp-booster
      evil-helix
      exiftool
      fd
      ffmpeg
      fzf
      gawk
      gh
      git
      git-lfs
      go
      gopls
      gnumake
      gnused
      gnutar
      graphite-cli
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
      oh-my-zsh
      okta-aws-cli
      opam
      pcre
      poetry
      postgresql_15_jit
      pre-commit
      protobuf
      rustup
      shellcheck
      shfmt
      speedtest-go
      starship
      terraform
      # texlive.combined.scheme-full
      time
      tree-sitter
      uv
      vsce
      vscode
      wget
      wordnet
      yaml-language-server
      yarn
      yq-go
      zsh-autosuggestions
      zsh-syntax-highlighting
    ];
  };
  programs = {
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      sessionVariables = {
        PATH = "$HOME/.emacs.d/bin:$HOME/.local/bin:$PATH";
        BAT_THEME = "Nord";
        AWS_PROFILE = "engineer";
        EDITOR = "${pkgs.evil-helix}/bin/hx";
      };
      enableCompletion = true;
      syntaxHighlighting.enable = true;

      autosuggestion.enable = true;

      shellAliases = {
        ls = "${pkgs.lsd}/bin/lsd";
        esrestart = "launchctl kickstart -k gui/502/org.nixos.emacs";
        eswhere = "lsof -c emacs | grep emacs$UID/server | grep -E -o '[^[:blank:]]*$' | head -n 1";
        et = "${pkgs.emacs30}/bin/emacsclient -nw -s $(eswhere)";
        magit = "git rev-parse --show-toplevel &> /dev/null && ${pkgs.emacs}/bin/emacsclient -nw -s $(eswhere) --eval '(magit-status)'";
        agenda = ''${pkgs.emacs}/bin/emacsclient -nw -s $(eswhere) --eval '(org-agenda nil "c")' '';
        todo = ''${pkgs.emacs}/bin/emacsclient -nw -s $(eswhere) --eval '(org-capture nil "t")' '';
        icat = "kitty +kitten icat";
        ssh = "kitty +kitten ssh";
        rebuild = "sudo darwin-rebuild switch --flake $HOME/nix-darwin && source ~/.zshrc";
        stoplinuxbox = "${pkgs.awscli2}/bin/aws ec2 stop-instances --profile engineer-sandbox --instance-ids i-02146285258ff4d08";
        linuxbox = "${pkgs.awscli2}/bin/aws ec2-instance-connect ssh --private-key-file ~/.ssh/aws_sandbox_ec2 --profile engineer-sandbox --os-user root --instance-id i-02146285258ff4d08";
        # claude-box: c6i.12xlarge build box in the dev VPC; reached over tailscale at its stable private IP; ssh auto-attaches the 'claude' tmux session
        stopclaudebox = "${pkgs.awscli2}/bin/aws ec2 stop-instances --profile engineer-sandbox --instance-ids i-019b0d7da7ac06c0b";
        # connecting auto-attaches the persistent 'claude' tmux session (via claude-tmux in the box's .bashrc), so you land in the live run.
        # detach with Ctrl-b then d to leave it running; reconnect anytime with claudebox. if it doesn't auto-attach, run: claude-tmux
        claudebox = "ssh -i ~/.ssh/aws_sandbox_ec2 ubuntu@172.16.1.23";
        "rec" = "${pkgs.asciinema}/bin/asciinema rec";
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
        ## Advanced shell functions
        function rgd() {
          ${pkgs.ripgrep}/bin/rg --json -C 2 "$@" | ${pkgs.delta}/bin/delta
        }
        function login-aws() {
          ${pkgs.awscli2}/bin/aws sso login --sso-session semgrep
          ${pkgs.awscli2}/bin/aws ecr get-login-password | ${pkgs.docker}/bin/docker login --username AWS --password-stdin 338683922796.dkr.ecr.us-west-2.amazonaws.com
        }

        function login-aws-sandbox() {
          ${pkgs.awscli2}/bin/aws sso login --sso-session semgrep --profile engineer-sandbox
          ${pkgs.awscli2}/bin/aws ecr get-login-password | ${pkgs.docker}/bin/docker login --username AWS --password-stdin 533267142541.dkr.ecr.us-west-2.amazonaws.com
        }

        function startlinuxbox() {
          ${pkgs.awscli2}/bin/aws ec2 start-instances --profile engineer-sandbox --instance-ids i-02146285258ff4d08
          ip_addr=$(${pkgs.awscli2}/bin/aws ec2 describe-instances --profile engineer-sandbox --instance-ids i-02146285258ff4d08 --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)
          echo "Host linuxbox\n\tHostname $ip_addr\n\tUser root\n\tIdentityFile ~/.ssh/aws_sandbox_ec2" > ~/.ssh/aws_box_config
        }

        # start the claude-box and wait until sshd is actually accepting (running-state alone is too early)
        function startclaudebox() {
          ${pkgs.awscli2}/bin/aws ec2 start-instances --profile engineer-sandbox --instance-ids i-019b0d7da7ac06c0b
          ${pkgs.awscli2}/bin/aws ec2 wait instance-running --profile engineer-sandbox --instance-ids i-019b0d7da7ac06c0b
          echo -n "claude-box running; waiting for sshd"
          until /usr/bin/ssh -i ~/.ssh/aws_sandbox_ec2 -o StrictHostKeyChecking=accept-new -o ConnectTimeout=3 -o BatchMode=yes ubuntu@172.16.1.23 true 2>/dev/null; do
            echo -n "."; sleep 3
          done
          echo " ready — connect with: claudebox"
        }

        function vlf() {
          ${pkgs.emacs30}/bin/emacsclient -nw -s $(eswhere) --eval "(vlf \"$1\")"
        }

        ## Terminal settings
        # So we get some nice things from vterm
        if [[ "$INSIDE_EMACS" = 'vterm' ]] \
            && [[ -n ''${EMACS_VTERM_PATH} ]] \
            && [[ -f ''${EMACS_VTERM_PATH}/etc/emacs-vterm-zsh.sh ]]; then
          source ''${EMACS_VTERM_PATH}/etc/emacs-vterm-zsh.sh
        fi

        # So we get proper colors from emacs in the terminal
        # ln -s -F ${pkgs.kitty.terminfo.outPath}/share/terminfo/78/xterm-kitty ~/.terminfo/78/xterm-kitty

        # eval opam if we arent in the semgrep flake dir
        if [[ -z "''${SEMGREP_NIX_BUILD-}" ]]; then
          eval $(opam env)
        fi
        # add cargo bin to path
        export PATH="$HOME/.cargo/bin:$PATH"

        # Doesn't work when set in session vars for some reason
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
