{ system ? builtins.currentSystem
, testing ? import dependencies/nixpkgs/nixos/lib/testing.nix { inherit system; }
, ... }:
with testing;
let
  configCommon =
  {
     imports = [ ./modules ];
     networking.extraHosts = ''
       127.0.0.1 www.machine
     '';
  };
in {
  base = makeTest
  {
    name = "test-base";
    machine = { config, pkgs, ... }: configCommon // {
    };
    testScript = ''
      startAll;
      $machine->waitForUnit("network.target");
    '';
  };

  publicWiki = makeTest
  {
    name = "test-public-wiki";
    machine = { config, pkgs, ... }: configCommon // {
       services.publicWiki.enable = true;
    };

    testScript = ''
      startAll;
      $machine->waitForUnit("network.target");
      $machine->waitUntilSucceeds("curl -L http://machine/");
      $machine->mustSucceed("curl -L http://machine/Front%20Page");
      $machine->mustSucceed("curl -L http://www.machine/");
      $machine->mustSucceed("curl -L http://www.machine/Front%20Page");
    '';
  };

  userWikis = makeTest
  {
    name = "test-user-wikis";
    machine = { config, pkgs, ... }: configCommon // {
       services.publicWiki.enable = true;
       services.userWikis.enable = true;
       users.extraUsers= [
         {
           name = "user_0";
           extraGroups = [ "cap-public-data" ];
           isNormalUser = true;
           wiki =
           {
             enable = true;
             accessCode = "user_0";
           };
         }
         {
           name = "user_1";
           extraGroups = [ "cap-public-data" ];
           isNormalUser = true;
           wiki =
           {
             enable = false;
           };
         }
         {
           name = "user_2";
           isNormalUser = true;
         }
       ];
    };

    testScript = ''
      startAll;
      $machine->waitForUnit("network.target");
      $machine->waitForUnit("user-user_0-wiki.service");
      $machine->waitUntilSucceeds("curl -L http://machine/");
      $machine->waitUntilSucceeds("curl -I http://www.machine/user/user_0/ | grep '200 OK'");
      $machine->waitUntilSucceeds("curl -IL http://www.machine/user/user_0 | grep '200 OK'");
      $machine->mustSucceed("curl -IL http://www.machine/user/user_1 | grep '404 Not Found'");
    '';
  };
}
