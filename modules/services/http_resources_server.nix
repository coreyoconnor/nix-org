{config, pkgs, lib, ...}:
with lib;
let
  cfg = config.services.httpResourcesServer;
  sharingCfg = config.resourcesSharing;
  nginxCfg = config.services.nginx;
in {
  options.services =
  {
    httpResourcesServer =
    {
      enable = mkOption
      {
        default = false;
        type = types.bool;
      };

      routes = mkOption
      {
        default = "";
        type = types.lines;
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

              ${cfg.routes}
          }

          server {
              listen 80;
              server_name ${sharingCfg.primaryDomain}
                  ${concatStringsSep " " sharingCfg.secondaryDomains}
                  ${concatStringsSep " " (map (domain: "www." + domain) sharingCfg.secondaryDomains)};

              rewrite ^/(.*) http://www.${sharingCfg.primaryDomain}/$1 redirect;
          }
        }
      '';

      systemd.services.nginx.serviceConfig =
      {
        NoNewPrivileges = "true";
        ProtectHome = "true";
      };
  };
}
