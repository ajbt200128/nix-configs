{
  description = "Austin Work Nix";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Private repo; fetched over SSH using your git creds (flake = false => plain source tree).
    devops-tools = {
      url = "git+ssh://git@github.com/semgrep/devops-tools.git?ref=develop";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      devops-tools,
    }:
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#MacBook-Pro-7
      darwinConfigurations."MacBook-Pro-7" = nix-darwin.lib.darwinSystem {

        modules = [
          ./configuration.nix
          {
            nixpkgs.overlays = [
              (final: _prev: {
                ckc = final.callPackage ./ckc.nix { src = devops-tools; };
              })
            ];
          }
          home-manager.darwinModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.r2cuser = import ./home.nix;
            };
            users.users.r2cuser = {
              name = "r2cuser";
              home = "/Users/r2cuser";
            };
          }
        ];
      };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MacBook-Pro-5".pkgs;
    };
}
