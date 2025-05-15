# use emacs-plus patches on osx

# relevant links:
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/emacs/generic.nix
# https://github.com/nix-community/emacs-overlay/blob/master/overlays/emacs.nix
# https://github.com/d12frosted/homebrew-emacs-plus/tree/master/patches/emacs-30

self: super:

let
  # configuration shared for all systems
  emacsGeneric = super.emacs.override {
    withSQLite3 = true;
    withWebP = true;
    withImageMagick = true;
    # have to force this; lib.version check wrong or because emacsGit?
    withTreeSitter = true;
    # broken on 15.4
    withNativeCompilation = true;
  };
  emacsPatched = emacsGeneric.overrideAttrs (old: {
    env = old.env // {
      NIX_CFLAGS_COMPILE = (old.env.NIX_CFLAGS_COMPILE or "")
        + " -DFD_SETSIZE=65536 -DDARWIN_UNLIMITED_SELECT";
    };
    patches = (old.patches or [ ]) ++ [
      # Fix OS window role so that yabai can pick up Emacs
      (super.fetchpatch {
        url =
          "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-28/fix-window-role.patch";
        sha256 = "+z/KfsBm1lvZTZNiMbxzXQGRTjkCFO4QPlEK35upjsE=";
      })
      # Add setting to enable rounded window with no decoration (still
      # have to alter default-frame-alist)
      (super.fetchpatch {
        url =
          "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/round-undecorated-frame.patch";
        sha256 = "uYIxNTyfbprx5mCqMNFVrBcLeo+8e21qmBE3lpcnd+4=";
      })
      # Respect system-appearances
      (super.fetchpatch {
        url =
          "https://raw.githubusercontent.com/d12frosted/homebrew-emacs-plus/master/patches/emacs-30/system-appearance.patch";
        sha256 = "3QLq91AQ6E921/W9nfDjdOUWR8YVsqBAT/W9c1woqAw=";
      })
    ];
  });
  emacs = (super.emacsPackagesFor emacsPatched).emacsWithPackages
    (epkgs: [ epkgs.jinx epkgs.vterm epkgs.org-pdftools epkgs.pdf-tools ]);
in { inherit emacs; }
