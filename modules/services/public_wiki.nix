{config, pkgs, lib, ...}:
with lib;
let cfg = config.services.public_wiki;
in {
  options.services.public_wiki =
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
