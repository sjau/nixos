{ stdenv, fetchurl, pcsclite, callPackage }:
let
  pin-entry = callPackage ./swisssign-pin-entry.nix {};
in
stdenv.mkDerivation rec {
  name = "suisseid-pkcs11-${version}";
  version = "1.0.4292";

  src = fetchurl {
    url = "http://update.swisssign.com/media/stick/repository/dists/unstable"
        + "/non-free/binary-amd64/suisseid-pkcs11_1.0.4292-1_amd64.deb";
    sha256 = "21af0722fb6d7e78a34ed1982b3978a78a3ce86aec9a23af6b269d74c02c1717";
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