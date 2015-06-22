{ config, pkgs, lib, ... }:
with lib;
let cfg = config.resources_sharing;
in {
  imports =
  [
    ./services/http_resources_server.nix
  ];

  options.resources_sharing =
  {
    advertise = mkOption
    {
      default = false;
      type = types.uniq types.bool;
    };
    
    users = mkOption
    {
      default = [];
      type = types.listOf types.string;
      description = ''
        Users of the organization to have their artifacts visible to other users and access
        to org resources.
      '';
    };

    userWikisBasePort = mkOption
    {
      default = 5000;
      type = types.int;
      description = ''
        Listen port of each user's wiki is bound to 5000 + uid.
      '';
    };

    primaryDomain = mkOption
    {
      default = config.networking.hostName;
      type = types.string;
    };

    secondaryDomains = mkOption
    {
      default = [];
      type = types.listOf types.string;
    };
  };

  config = mkIf cfg.advertise
  {
    services.avahi.enable = true;
    services.avahi.nssmdns = true;
  };
}
