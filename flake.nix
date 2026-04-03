{
  description = "OCaml bindings to libxkbcommon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        xkbcommon-package = pkgs.callPackage ./default.nix {};
      in {
        packages = {
          default = xkbcommon-package;
          xkbcommon = xkbcommon-package;
        };

        formatter = pkgs.alejandra;

        devShells.default = import ./shell.nix {inherit pkgs;};
      }
    );
}
