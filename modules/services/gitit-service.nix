{config, pkgs, lib}: options:
with lib;
let
  gitit = pkgs.haskellPackages.gitit;
  baseConf = ./gitit.conf;
  deployConf = pkgs.writeText "gitit-deploy.conf" ''
    address: 0.0.0.0
    # sets the IP address on which the web server will listen.

    port: ${toString options.port}
    # sets the port on which the web server will run.

    wiki-title: ${options.title}
    # the title of the wiki.

    base-url = ${options.baseUrl}

    repository-path: ${options.repoPath}

    # specifies the path of the repository directory.  If it does not
    # exist, gitit will create it on startup.

    user-file: ${options.runDir}/gitit-users
    # specifies the path of the file containing user login information.
    # If it does not exist, gitit will create it (with an empty user list).
    # This file is not used if 'http' is selected for authentication-method.

    static-dir: ${options.repoPath}/static
    # specifies the path of the static directory (containing javascript,
    # css, and images).  If it does not exist, gitit will create it
    # and populate it with required scripts, stylesheets, and images.

    templates-dir: ${options.repoPath}/templates
    # specifies the path of the directory containing page templates.
    # If it does not exist, gitit will create it with default templates.
    # Users may wish to edit the templates to customize the appearance of
    # their wiki. The template files are HStringTemplate templates.

    access-question: Code
    access-question-answers: ${options.accessCode}
    mime-types-file: ${pkgs.nginx}/conf/mime.types

    log-file: ${options.runDir}/gitit.log
  '';
in {
  description = "gitit wiki server ${options.name}";
  path = [ pkgs.git ];
  after = [ "network.target" ];
  wantedBy = [ "multi-user.target" ];

  preStart = ''
    if ! [ -f $HOME/.gitconfig ] ; then
      cp -n ${options.defaultGitconfig} $HOME/.gitconfig
    fi

    ${options.preStart}
  '';
  script = "${gitit}/bin/gitit -f ${deployConf} -f ${baseConf}";

  serviceConfig =
  {
    Restart = "always";
    RestartSec = "10s";
    TimeoutStartSec = "30s";
    User = options.user;
  };
}
