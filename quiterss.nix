{ stdenv, fetchurl, gcc, sqlite, pkgconfig, qt5 }:

stdenv.mkDerivation rec {
  name = "QuiteRSS-${version}";
  version = "0.18.6";

  sourceRoot = ".";

  src = fetchurl {
    url = "https://quiterss.org/files/0.18.6/QuiteRSS-0.18.6-src.tar.gz";
    sha256 = "1162a7878110f8fab0257d31bcfd37ebcf9610ddefaf3f35cd4af8b606a1f066";
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
