{config, pkgs, lib, ...}:
with lib;
let
  cfg = config.services.publicWiki;
  sharingCfg = config.resourcesSharing;
  gitit = pkgs.haskellPackages.gitit;
  baseConf = ./gitit.conf;
  repoPath = cfg.repoPath;
  deployConf = pkgs.writeText "gitit-deploy.conf" ''
    address: 0.0.0.0
    # sets the IP address on which the web server will listen.

    port: 5001
    # sets the port on which the web server will run.

    wiki-title: CoreyOConnor@gmail.com
    # the title of the wiki.

    base-url = http://www.${sharingCfg.primaryDomain}

    repository-path: ${repoPath}

    # specifies the path of the repository directory.  If it does not
    # exist, gitit will create it on startup.

    user-file: /var/lib/gitit/gitit-users
    # specifies the path of the file containing user login information.
    # If it does not exist, gitit will create it (with an empty user list).
    # This file is not used if 'http' is selected for authentication-method.

    static-dir: ${repoPath}/static
    # specifies the path of the static directory (containing javascript,
    # css, and images).  If it does not exist, gitit will create it
    # and populate it with required scripts, stylesheets, and images.

    templates-dir: ${repoPath}/templates
    # specifies the path of the directory containing page templates.
    # If it does not exist, gitit will create it with default templates.
    # Users may wish to edit the templates to customize the appearance of
    # their wiki. The template files are HStringTemplate templates.
    # Variables to be interpolated appear between $$'s. Literal $$'s must be
    # backslash-escaped.

    access-question: Code
    access-question-answers: ${cfg.accessCode}
    mime-types-file: ${pkgs.nginx}/conf/mime.types

    use-cache: yes
    cache-dir: /var/lib/gitit/cache
    # directory where rendered pages will be cached

    log-file: /var/lib/gitit/gitit.log
    # specifies the path of gitit's log file.  If it does not exist,
    # gitit will create it. The log is in Apache combined log format.
  '';
  gititGitconfig = pkgs.writeText "gitit-gitconfig" ''
    [user]
      name = Gitit
      email = gitit@${sharingCfg.primaryDomain}
  '';
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

    systemd.services.gitit =
    {
      description = "gitit wiki server";
      path = [ pkgs.git ];
      wantedBy = [ "nginx.service" ];

      preStart = ''
        if ! [ -f $HOME/.gitconfig ] ; then
          cp ${gititGitconfig} $HOME/.gitconfig
        fi
      '';
      script = "${gitit}/bin/gitit -f ${deployConf} -f ${baseConf}";

      serviceConfig =
      {
        NoNewPrivileges = "true";
        ProtectHome = "true";
        ReadWriteDirectories = "/var/lib/gitit ${repoPath}";
        Restart = "always";
        User = "gitit";
        WorkingDirectory = "/var/lib/gitit";
      };
    };

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
