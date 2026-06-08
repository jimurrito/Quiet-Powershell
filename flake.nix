{
  description = "Powershell fork that only logs Critical errors to systemd Journal";
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
      # Supported Architectures
      archs = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # package function that allows for arch specific pkgs to be provided
      mkPackage =
        pkgs:
        pkgs.powershell.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            echo '{"LogLevel":"Critical"}' > $out/share/powershell/powershell.config.json
          '';
        });
      # multi arch packager
      packager = sys: {
        ${sys}.default = {
          quietPowershell = mkPackage nixpkgs.legacyPackages.${sys};
        };
      };
    in
    {
      #
      # Builds a package per architecture supported
      packages = builtins.foldl' (acc: x: acc // x) { } (map packager archs);
      #
      # Nixpkgs overlay for the package(s)
      overlays.default = final: prev: {
        quietPowershell = mkPackage prev;
      };
      #
      # Default option to import package into the env
      nixosModules.default =
        { pkgs, ... }:
        {
          # Imports the overlay to put quietPwsh in pkgs
          nixpkgs.overlays = [ self.overlays.default ];
          environment.systemPackages = [ pkgs.quietPowershell ];
        };
      #
      #
      # TestVM
      nixosConfigurations = {
        test-vm = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            test-vm.baselineConfig
            self.nixosModules.default
          ];
        };
      };
    };
}
