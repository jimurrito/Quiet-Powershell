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
      #
      lib = nixpkgs.lib;
      #
      archs = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # multi arch packager
      packager = sys: {
        ${sys}.default =
          let
            pkgs = nixpkgs.legacyPackages.${sys};
          in
          {
            quietPowershell = pkgs.powershell.overrideAttrs (old: {
              postInstall = (old.postInstall or "") + ''
                echo '{"LogLevel":"Critical"}' > $out/share/powershell/powershell.config.json
              '';
            });
          };
      };
    in
    {
      #
      #
      #
      packages = builtins.foldl' (acc: x: acc // x) { } (map packager archs);
      #
      #
      nixosModules.default =
        { pkgs, ... }:
        let
          pkgsystem = pkgs.stdenv.hostPlatform.system;
        in
        {
          environment.systemPackages = [ self.packages.${pkgsystem}.default.quietPowershell ];
        };
      #
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
