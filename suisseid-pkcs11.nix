{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  name = "suisseid-pkcs11-${version}";
  version = "1.0.4292";

  src = fetchurl {
    url = "http://update.swisssign.com/media/stick/repository/dists/unstable"
        + "/non-free/binary-amd64/suisseid-pkcs11_1.0.4292-1_amd64.deb";
    sha256 = "05qp5k079796dfpj76pcdbl3r2m7g0wjp66i9siphzkdzci0gbr1";
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

