{config, pkgs, lib, ...}:
with lib;
{
  imports = [
    ./modules/services/public_wiki.nix
    ./modules/services/user_wikis.nix
    ./modules/resources_sharing.nix
  ];
}
