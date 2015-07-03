{config, pkgs, lib, ...}:
with lib;
let
  cfg = config.services.publicWiki;
  sharingCfg = config.resourcesSharing;
  gititService = import ./gitit-service.nix { inherit config pkgs lib; } {
    name = "public-wiki";
    port = 5001;
    title = "CoreyOConnor@gmail.com";
    baseUrl = "http://www.${sharingCfg.primaryDomain}";
    repoPath = cfg.repoPath;
    runDir = "/var/lib/gitit";
    accessCode = cfg.accessCode;
    defaultGitconfig = pkgs.writeText "gitit-gitconfig" ''
      [user]
        name = Gitit
        email = gitit@${sharingCfg.primaryDomain}
    '';
    user = "gitit";
    preStart = "";
  };
  hasCapPublicData = user: (any (group: group == "cap-public-data") user.extraGroups);
  # TODO: does not include "keys" of authorizedKeys attr set.
  allPublicKeysForPublicDataUsers = concatLists (mapAttrsToList (name: user:
      user.openssh.authorizedKeys.keyFiles
    ) (filterAttrs hasCapPublicData config.users.extraUsers));
in {
  options.services.publicWiki =
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

    repoPath = mkOption
    {
      default = "/var/lib/gitit/wikidata";
      type = types.uniq types.string;
    };
  };

  config = mkIf cfg.enable
  {
    services.httpResourcesServer.enable = true;
    
    services.httpResourcesServer.routes = ''
      location / {
        proxy_pass http://localhost:5001;
        proxy_set_header  X-Real-IP  $remote_addr;
        proxy_redirect off;
      }
    '';

    systemd.services.public-wiki = gititService;

    users.extraGroups =
    [
      { name = "gitit"; }
    ];

    users.extraUsers =
    {
      gitit =
      {
        description = "User that runs gitit";
        home = "/var/lib/gitit";
        createHome = true;
        group = "gitit";
        extraGroups = [ "cap-public-data" ];
        useDefaultShell = true;
        openssh.authorizedKeys.keyFiles = allPublicKeysForPublicDataUsers sharingCfg.users;
      };
    };
  };
}
