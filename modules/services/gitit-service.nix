{config, pkgs, lib}: options:
with lib;
let
  gitit = pkgs.haskellPackages.gitit;
  baseConf = ./gitit.conf;
  deployConf = pkgs.writeText "gitit-deploy.conf" ''
    address: 0.0.0.0
    # sets the IP address on which the web server will listen.

    port: ${options.port}
    # sets the port on which the web server will run.

    wiki-title: ${options.title}
    # the title of the wiki.

    base-url = ${options.baseUrl}

    repository-path: ${options.repoPath}

    # specifies the path of the repository directory.  If it does not
    # exist, gitit will create it on startup.

    user-file: ${options.userFile}
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
    # Variables to be interpolated appear between $'s. Literal $'s must be
    # backslash-escaped.

    access-question: Code
    access-question-answers: ${options.accessCode}
    mime-types-file: ${pkgs.nginx}/conf/mime.types

    log-file: ${options.logFilePath}
  '';
in {
  description = "gitit wiki server ${options.name}";
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
}
