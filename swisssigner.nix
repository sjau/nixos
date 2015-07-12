{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "swisssigner-${version}";
  version = "2.1.543";

  sourceRoot = ".";

  src = fetchurl {
    url = "http://update.swisssign.com/media/stick/repository/dists/unstable"
        + "/non-free/binary-amd64/swisssigner_2.1.543-1_amd64.deb";
    sha256 = "bd6e3afe67f2c1bd435016c090c433d222626d17c6e730a98fe5248a6ad84b1b";
  };

  unpackCmd = ''
    ar p "$src" data.tar.xz | tar xJ
  '';

  buildPhase = let
    rpaths = [ stdenv.gcc.gcc ];
  in ''
    for i in lib/*.so; do
      patchelf --set-rpath "${stdenv.lib.makeLibraryPath rpaths}" "$i"
    done
  '';

  dontStrip = true;

  installPhase = ''
    for i in lib/*.so; do
      install -vD "$i" "$out/lib/$(basename "$i")"
    done
  '';
}

