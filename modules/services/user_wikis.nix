{config, pkgs, lib, ...}:
with lib;
let
  cfg = config.services.userWikis;
  sharingCfg = config.resourcesSharing;
  userOptions =
  {
    org.wiki =
    {
      enable = mkOption
      {
        default = false;
        type = types.uniq types.bool;
      };

      accessCode = mkOption
      {
        default = "public";
        type = types.uniq types.string;
      };
    };
  };
in {
  options =
  {
    services.userWikis =
    {
      enable =
      {
        default = false;
        type = types.uniq types.bool;
      };
    };

    users.extraUsers = mkOption
    {
      options = [ userOptions ];
    };
  };

  config = mkIf cfg.enable
  {
  };
}
