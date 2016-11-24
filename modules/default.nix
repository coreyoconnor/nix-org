{config, pkgs, lib, ...}:
with lib;
{
  imports = [
    ./services/public_wiki.nix
    ./services/user_wikis.nix
    ./resources_sharing.nix
  ];
}
