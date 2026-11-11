{
  description = "Prodigal - An Axtremely customizable shell by Axenide";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    axctl = {
      url = "github:Axenide/axctl";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, axctl, ... }:
    let
      prodigalLib = import ./nix/lib.nix { inherit nixpkgs; };
      version = nixpkgs.lib.removeSuffix "\n" (builtins.readFile ./version);
    in {
      nixosModules.default = { pkgs, lib, ... }: {
        imports = [ ./nix/modules ];
        programs.prodigal.enable = lib.mkDefault true;
        programs.prodigal.package = lib.mkDefault self.packages.${pkgs.system}.default;
      };

      packages = prodigalLib.forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          lib = nixpkgs.lib;

          Prodigal = import ./nix/packages {
            inherit pkgs lib self system axctl version;
          };
        in {
          default = Prodigal;
          Prodigal = Prodigal;
        }
      );

      devShells = prodigalLib.forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          Prodigal = self.packages.${system}.default;
        in {
          default = pkgs.mkShell {
            packages = [ Prodigal ];
            shellHook = ''
              export QML2_IMPORT_PATH="${Prodigal}/lib/qt-6/qml:$QML2_IMPORT_PATH"
              export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
              echo "Prodigal dev environment loaded."
            '';
          };
        }
      );

      apps = prodigalLib.forAllSystems (system:
        let
          Prodigal = self.packages.${system}.default;
        in {
          default = {
            type = "app";
            program = "${Prodigal}/bin/prodigal";
          };
        }
      );
    };
}
