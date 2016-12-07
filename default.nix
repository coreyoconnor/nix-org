{ system ? builtins.currentSystem
, ... }:
let
  test = import ./test.nix { inherit system; };
in {
  inherit test;
}
