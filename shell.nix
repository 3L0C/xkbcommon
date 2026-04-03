{pkgs ? import <nixpkgs> {}}: let
  xkbcommon-package = pkgs.callPackage ./default.nix {};
in
  pkgs.mkShell {
    buildInputs = [pkgs.ocamlPackages.alcotest];
    inputsFrom = [xkbcommon-package];

    nativeBuildInputs = builtins.attrValues {
      inherit
        (pkgs)
        pkg-config
        alejandra
        ;

      inherit
        (pkgs.ocamlPackages)
        ocaml-lsp
        ocamlformat
        utop
        ;
    };

    shellHook = ''
      echo ""
      echo "xkbcommon-ocaml development environment"
      echo "libxkbcommon: $(pkg-config --modversion xkbcommon)"
      echo ""
    '';
  }
