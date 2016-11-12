{config, pkgs, lib, ...}:
with lib;
let
  cfg = config.services.userWikis;
  sharingCfg = config.resourcesSharing;
  allUsersList = attrValues config.users.extraUsers;
  enabledUsersList = filter (user: user.wiki.enable) allUsersList;
  withPorts = imap (i: user: user // { port = sharingCfg.userWikisBasePort + i; }) enabledUsersList;
  routeForUserWiki = user: ''
    location /user/${user.name}/ {
      proxy_pass http://localhost:${toString user.port}/;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_redirect off;
    }
  '';
  catchAll = ''
    location /user/ {
      rewrite ^/user/.*$ /Unknown%20User break;
    }
  '';
  routes = concatStringsSep "\n" ((map routeForUserWiki withPorts) ++ [catchAll]);
  mkGititService = import ./gitit-service.nix { inherit config pkgs lib; };
  mkUserWikiService = user: mkGititService {
    name = "user-${user.name}-wiki";
    port = user.port;
    title = "${user.name}'s wiki";
    baseUrl = "http://www.${sharingCfg.primaryDomain}/user/${user.name}";
    repoPath = user.home + "/wiki/data";
    runDir = user.home + "/wiki";
    accessCode = user.wiki.accessCode;
    defaultGitconfig = pkgs.writeText "default-${user.name}-gitconfig" ''
      # this should not show up in /var
      [user]
        name = ${user.name}
        email = ${user.name}@${sharingCfg.primaryDomain}
    '';
    user = user.name;
    preStart = ''
      mkdir -p ${user.home}/wiki
    '';
  };
  services = listToAttrs (map (user:
  {
    name = "user-${user.name}-wiki";
    value = mkUserWikiService user;
  }) withPorts);
  userOptions =
  {
    wiki =
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
      enable = mkOption
      {
        default = false;
        type = types.bool;
      };
    };

    users.users = mkOption
    {
      options = [ userOptions ];
    };
  };

  config = mkIf cfg.enable
  {
    services.httpResourcesServer =
    {
      enable = true;
      routes = routes;
    };

    systemd.services = services;
  };
}
