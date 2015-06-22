{config, pkgs, lib, ...}:
with lib;
let
  cfg = config.services.http_resources_server;
  sharingCfg = config.resources_sharing;
  nginxCfg = config.services.nginx;
in {
  options.services =
  {
    http_resources_server =
    {
      enable = mkOption
      {
        default = false;
        type = types.uniq types.bool;
      };

      routes = mkOption
      {
        default = [];
        type = types.listOf types.lines;
      };
    };

    nginx =
    {
      events = mkOption
      {
        default = ''
          worker_connections 4096;
        '';
        type = types.lines;
      };
    };
  };

  config = mkIf cfg.enable
  {
      networking.firewall.allowedTCPPorts = [ 80 ];

      services.nginx.enable = true;

      services.nginx.config = ''
        events {
          ${nginxCfg.events}
        }
        http {
          sendfile on;
          include ${pkgs.nginx}/conf/mime.types;

          server {
              listen 80;
              server_name www.${sharingCfg.primaryDomain};

              ${concatStringsSep "\n" cfg.routes}
          }

          server {
              listen 80;
              server_name ${sharingCfg.primaryDomain}
                  ${concatStrings sharingCfg.secondaryDomains};

              rewrite ^/(.*) http://www.${sharingCfg.primaryDomain}/$1 redirect;
          }
        }
      '';
  };
}
