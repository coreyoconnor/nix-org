{config, pkgs, lib, ...}:
with lib;
let cfg = config.services.user_wikis;
in {
  options.services.user_wikis =
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
