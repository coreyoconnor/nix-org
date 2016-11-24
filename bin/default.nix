{ system ? builtins.currentSystem
, pkgs ? import dependencies/nixpkgs { config = ./config.nix }
}: {
  inherit pkgs;
  glng = pkgs.substituteAll {
    src = glngn-launcher.sh;
    inherit pkgs;
  };
}
