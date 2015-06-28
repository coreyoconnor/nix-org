{ system ? builtins.currentSystem, ... }:
with import (<nixos> + "/lib/testing.nix") { inherit system; };
{
  testPublicWiki = makeTest
  {
    name = "test-public-wiki-only";
    machine = { config, pkgs, ... }: {
       imports = [ ./default.nix ];
       services.publicWiki.enable = true;
       networking.extraHosts = ''
         127.0.0.1 www.machine
       '';
    };

    testScript = ''
      startAll;
      $machine->waitForUnit("multi-user.target");
      $machine->waitUntilSucceeds("curl -L http://machine/");
      $machine->waitUntilSucceeds("curl -L http://machine/Front%20Page");
      $machine->waitUntilSucceeds("curl -L http://www.machine/");
      $machine->waitUntilSucceeds("curl -L http://www.machine/Front%20Page");
    '';
  };

  testUserWiki = makeTest
  {
    name = "test-user-wikis";
    machine = { config, pkgs, ... }: {
       imports = [ ./default.nix ];
       services.publicWiki.enable = true;
       services.userWikis.enable = true;
       networking.extraHosts = ''
         192.168.0.1 www.machine
       '';
    };

    testScript = ''
      startAll;
      $machine->waitForUnit("multi-user.target");
      $machine->waitUntilSucceeds("curl -L http://machine/");
      $machine->waitUntilSucceeds("curl -L http://machine/user/user_0");
    '';
  };
}
