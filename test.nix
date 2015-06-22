{ system ? builtins.currentSystem, ... }:
with import (<nixos> + "/lib/testing.nix") { inherit system; };
{
  testPublicOnly = makeTest
  {
    name = "test-public-wiki-only";
    machine = { config, pkgs, ... }: {
       imports = [ ./default.nix ];
       services.public_wiki.enable = true;
       services.http_resources_server.enable = true;
    };

    testScript = ''
      startAll;
      $machine->waitForUnit("multi-user.target");
      $machine->waitUntilSucceeds("curl http://machine/");
    '';
  };
}
