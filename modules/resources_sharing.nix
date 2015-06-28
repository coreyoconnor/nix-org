{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.resourcesSharing;
in {
  imports =
  [
    ./services/http_resources_server.nix
  ];

  options.resourcesSharing =
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
        User names of the organization that have their artifacts visible to other users and RW access
        to org public and private resources.
      '';
    };

    userWikisBasePort = mkOption
    {
      default = 6000;
      type = types.uniq types.int;
      description = ''
        Listen port of each user's wiki is bound to 6000 + index in users list.
      '';
    };

    primaryDomain = mkOption
    {
      default = config.networking.hostName;
      type = types.uniq types.string;
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

  } // {
    users.extraGroups = 
    [
      { name = "cap-private-data"; }
      { name = "cap-public-data"; }
    ];
  };
}
