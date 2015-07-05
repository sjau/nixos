{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "swisssign-pin-entry-${version}";
  version = "1.0.151";

  src = fetchurl {
    url = "http://update.swisssign.com/media/stick/repository/dists/unstable"
        + "/non-free/binary-amd64/swisssign-pin-entry_1.0.151-1_amd64.deb";
    sha256 = "4c4d08f19d671a9a1bbf68fa2f6e0624775ff68fccfc4ce3832030734088a287";
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

