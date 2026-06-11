{ lib, buildGoModule, src }:

# `ckc` lives in the ckc/ subdir of semgrep/devops-tools and ships two binaries.
buildGoModule {
  pname = "ckc";
  version = "develop-${src.shortRev or "dirty"}";

  inherit src;
  modRoot = "ckc";

  vendorHash = "sha256-QWYm2i5feFyLDJoELGk+6hBLGPm821cLo5UJSIa3XE8=";

  subPackages = [
    "cmd/ckc"
    "cmd/ckc-auth"
  ];

  meta = {
    description = "Auto-discovering drop-in replacement for the ckc cluster-connect shell function";
    homepage = "https://github.com/semgrep/devops-tools/tree/develop/ckc";
    mainProgram = "ckc";
    platforms = lib.platforms.unix;
  };
}
