{ system ? builtins.currentSystem, ... }:
with import (<nixpkgs> + "/nixos/lib/testing.nix") { inherit system; };
let
  testConfigCommon =
  {
     imports = [ ./default.nix ];
     networking.extraHosts = ''
       127.0.0.1 www.machine
     '';
  };
in {
  testPublicWiki = makeTest
  {
    name = "test-public-wiki-only";
    machine = { config, pkgs, ... }: testConfigCommon // {
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

  testUserWikis = makeTest
  {
    name = "test-user-wikis";
    machine = { config, pkgs, ... }: testConfigCommon // {
       services.publicWiki.enable = true;
       services.userWikis.enable = true;
       users.extraUsers= [
         {
           name = "user_0";
           extraGroups = [ "cap-public-data" ];
           isNormalUser = true;
           org.wiki =
           {
            enable = true;
            accessCode = "user_0";
           };
         }
         {
           name = "user_1";
           extraGroups = [ "cap-public-data" ];
           isNormalUser = true;
           org.wiki =
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
