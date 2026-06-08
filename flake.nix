{
  description = "<PROJECT DESCRIPTION>";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    test-vm.url = "github:jimurrito/nixos-test-vm";
  };
  #
  outputs =
    {
      self,
      nixpkgs,
      test-vm,
    }:
    let
      #
      lib = nixpkgs.lib;
      #
      archs = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      #
      packager = sys: {
        ${sys}.default =
          let
            pkgs = nixpkgs.legacyPackages.${sys};
          in
          with lib;
          pkgs.stdenv.mkDerivation {
            pname = "PACKAGE-NAME";
            meta.mainProgram = "PACKAGE-NAME";
            version = "0.1.0";
            src = ./.;
            dontBuild = true;
            #
            installPhase = ''
              #
              # see under ./derivation-examples for references
              #
            '';
          };
      };
      #
    in
    {
      #
      #
      #
      # Builds packages for each arch provided
      # (') is required so foldl will be strict and not lazy
      packages = builtins.foldl' (acc: x: acc // x) { } (map packager archs);
      #
      #
      #
      # <Just package>
      nixosModules.package =
        {
          pkgs,
          ...
        }:
        let
          pkgsystem = pkgs.stdenv.hostPlatform.system;
          mainpackage = self.packages.${pkgsystem}.default;
        in
        {
          # config to be implemented via the `options`
          config.environment.systemPackages = [
            mainpackage
          ];
        };
      #
      #
      #
      # <PACKAGE + service via Options>
      nixosModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          pkgsystem = pkgs.stdenv.hostPlatform.system;
          mainpackage = self.packages.${pkgsystem}.default;
          PACKAGE-NAME-nixops = config.services.PACKAGE-NAME;
        in
        with lib;
        {
          # Options for services overlay
          options.services.PACKAGE-NAME = {
            enable = mkEnableOption "IonUpdate scheduled service";
            example = mkOption {
              type = types.str;
              default = "<Option default>";
              description = "<Option Description>";
            };
          };
          #
          # config to be implemented via the `options`
          config = mkIf PACKAGE-NAME-nixops.enable {
            # Imports package and runs the install steps
            environment.systemPackages = [
              mainpackage
            ];
            # rootless identity
            users = {
              groups.PACKAGE-NAME = { };
              users.PACKAGE-NAME = {
                enable = true;
                group = "PACKAGE-NAME";
                isSystemUser = true;
              };
            };
            # systemd service
            systemd = {
              services.PACKAGE-NAME = {
                description = "PACKAGE-NAME service";
                path = with pkgs; [
                  powershell
                ];
                serviceConfig = with lib; {
                  Type = "oneshot";
                  User = "PACKAGE-NAME";
                  Group = "PACKAGE-NAME";
                  ExecStart = ''
                    ${getExe mainpackage} <PACKAGE ARGS 4 Service>
                  '';
                };
              };
              timers.PACKAGE-NAME = {
                description = "PACKAGE-NAME timer";
                wantedBy = [ "timers.target" ];
                timerConfig = {
                  OnCalendar = PACKAGE-NAME-nixops.interval;
                  Persistent = true;
                };
              };
            };
          };
        };
      #
      #
      #
      # TestVM
      nixosConfigurations =
        let
          testConfig =
            { ... }:
            {
              /*
                Your test config
                here
              */
            };
        in
        {
          test-vm = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              test-vm.baselineConfig
              # test config
              self.nixosModules.default
              testConfig
            ];
          };
        };
    };
}
