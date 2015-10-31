{ stdenv, fetchurl, gcc, sqlite, pkgconfig, qt5 }:

stdenv.mkDerivation rec {
  name = "QuiteRSS-${version}";
  version = "0.18.2";

  sourceRoot = ".";

  src = fetchurl {
    url = "http://quiterss.org/files/0.18.2/QuiteRSS-0.18.2-src.tar.gz";
    sha256 = "d335529541d2824d66c941b68a34425929402d9c95716446a55ac0ceb777d18d";
  };

  buildInputs = [ qt5.base sqlite pkgconfig qt5.webkit qt5.multimedia qt5.tools ];
  
  configurePhase = "qmake CONFIG+=release PREFIX=$out DESTDIR=$out QuiteRSS.pro";

  meta = with stdenv.lib; {
    description = "A multi-platform rss reader.";
    homepage = https://quiterss.org/;
    license = licenses.gpl3;
    maintainers = [ hyper_ch ];
    platforms = platforms.all;
  };
}
