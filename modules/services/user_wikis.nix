{config, pkgs, lib, ...}:
with lib;
let
  cfg = config.services.userWikis;
  sharingCfg = config.resourcesSharing;
in {
  options.services.userWikis =
  {
    enable =
    {
      default = false;
      type = types.uniq types.bool;
    };
  };

  config = mkIf cfg.enable
  {
  };
}
