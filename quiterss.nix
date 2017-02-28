{ stdenv, fetchurl, gcc, sqlite, pkgconfig, qt5 }:

stdenv.mkDerivation rec {
  name = "QuiteRSS-${version}";
  version = "0.18.4";

  sourceRoot = ".";

  src = fetchurl {
    url = "http://quiterss.org/files/0.18.4/QuiteRSS-0.18.4-src.tar.gz";
    sha256 = "e53ddcab32ed4894ee59afd0db5d7ab86248986fdf6e1c1aeec9c8a841867a9c";
  };

  buildInputs = [ qt5.qtbase sqlite pkgconfig qt5.qtwebkit qt5.qtmultimedia qt5.qttools qt5.qmakeHook ];
  
  meta = with stdenv.lib; {
    description = "A multi-platform rss reader.";
    homepage = https://quiterss.org/;
    license = licenses.gpl3;
    maintainers = [ hyper_ch ];
    platforms = platforms.all;
  };
}
