# quiet-powershell

![Nix](https://img.shields.io/badge/lang-Nix-5277C3?logo=nixos)
![License](https://img.shields.io/badge/license-GPL--3.0-blue)

A Nix flake that provides a patched build of PowerShell configured to only emit `Critical`-level messages to the systemd Journal. Useful for reducing PowerShell noise in `journalctl` on systemd services that use Powershell.

## Table of Contents

- [Requirements](#requirements)
- [Usage](#usage)
- [Flake Outputs](#flake-outputs)
- [License](#license)

## Requirements

- Nix with flakes enabled
- Supported architectures: `x86_64-linux`, `aarch64-linux`

## Usage

Add `nixosModules.default` to your NixOS configuration. This registers the overlay and adds `quietPowershell` to `environment.systemPackages`, making `pkgs.quietPowershell` available to all other modules in the system.

**Pseudo-code:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-<version>";
    quiet-powershell.url = "github:jimurrito/quiet-powershell";
  };

  outputs = { nixpkgs, quiet-powershell, ... }: {
    nixosConfigurations.<hostname> = nixpkgs.lib.nixosSystem {
      system = "<system>";
      modules = [
        quiet-powershell.nixosModules.default
        ({ pkgs, ... }: {
          systemd.services.<service-name> = {
            serviceConfig.ExecStart = "${pkgs.quietPowershell}/bin/pwsh -File /path/to/script.ps1";
          };
        })
      ];
    };
  };
}
```

**Real example:**

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    quiet-powershell.url = "github:jimurrito/quiet-powershell";
  };

  outputs = { nixpkgs, quiet-powershell, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        quiet-powershell.nixosModules.default
        ({ pkgs, ... }: {
          systemd.services.my-ps-job = {
            description = "My PowerShell background job";
            wantedBy = [ "multi-user.target" ];
            serviceConfig = {
              ExecStart = "${pkgs.quietPowershell}/bin/pwsh -File /etc/my-ps-job/run.ps1";
              Restart = "on-failure";
            };
          };
        })
        ./configuration.nix
      ];
    };
  };
}
```

## Flake Outputs

| Output | Type | Description |
|---|---|---|
| `packages.<system>.default.quietPowershell` | package | The patched PowerShell derivation with `LogLevel` set to `Critical` |
| `overlays.default` | overlay | Injects `quietPowershell` into `pkgs` |
| `nixosModules.default` | NixOS module | Registers the overlay and adds `quietPowershell` to `environment.systemPackages` |

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE.md).
