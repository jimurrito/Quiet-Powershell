# Powershell Package example

## Example

```nix
pkgs.stdenv.mkDerivation {
  pname = "PACKAGE-NAME";
  meta.mainProgram = "PACKAGE-NAME";
  version = "0.1.0";
  src = ./.;
  dontBuild = true;
  #
  installPhase = ''
    #
    # <Example (pwsh>
    #
    moduleDir="$out/module"
    mkdir -p "$moduleDir"
    cp IonUpdate.ps1 IonUpdate.psd1 IonUpdate.psm1 "$moduleDir/"
    mkdir -p "$out/bin"
    cat > "$out/bin/ion-update" << EOF
    #!/usr/bin/env bash
    export PSModulePath="$moduleDir:\$PSModulePath"
    ${lib.getExe pkgs.powershell} -NonInteractive -Command "$moduleDir/IonUpdate.ps1 \$@"
    EOF
    chmod +x "$out/bin/ion-update"
  '';
};
```

## Quiet Powershell

```nix
# Inject powershell.config.json into $PSHOME
# Without this, powershell is verbose log a bunch of random crap when used in a systemd service.
quietPowershell = pkgs.powershell.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    echo '{"LogLevel":"Critical"}' > $out/share/powershell/powershell.config.json
  '';
});
```
