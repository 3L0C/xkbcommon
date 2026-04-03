{
  lib,
  ocamlPackages,
  libxkbcommon,
  pkg-config,
}:
ocamlPackages.buildDunePackage {
  pname = "xkbcommon";
  version = "0.1.0";
  duneVersion = "3";

  src = lib.cleanSource ./.;

  buildInputs = builtins.attrValues {
    inherit
      (ocamlPackages)
      dune-configurator
      ;
    inherit libxkbcommon;
  };

  nativeBuildInputs = [pkg-config];

  checkInputs = [ocamlPackages.alcotest];

  meta = {
    description = "OCaml bindings to libxkbcommon";
    homepage = "https://github.com/talex5/xkbcommon";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
