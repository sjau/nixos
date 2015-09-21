{ stdenv, fetchurl }:
stdenv.mkDerivation rec {
  name = "exactimage-${version}";
  version = "0.9.1";

  src = fetchurl {
    url = "http://dl.exactcode.de/oss/exact-image/exact-image-0.9.1.tar.bz2";
    sha256 = "79e6a58522897f9740aa3b5a337f63ad1e0361a772141b24aaff2e31264ece7d";
  };

  unpackCmd = ''
    ar p "$src" data.tar.xz | tar xJ
  '';

  buildPhase = let
    rpaths = [ pcsclite stdenv.cc.cc ];
  in ''
    for i in lib/*.so; do
      echo "${stdenv.lib.makeLibraryPath rpaths}"
      echo "$i"
      patchelf --set-rpath "${stdenv.lib.makeLibraryPath rpaths}" "$i"
    done
  '';

  dontStrip = true;

  installPhase = ''
    for i in lib/*.so; do
      install -vD "$i" "$out/lib/$(basename "$i")"
    done

    ln -s ${pin-entry}/lib/libcvP11LCB.so $out/lib/libcvP11LCB.so
  '';
}