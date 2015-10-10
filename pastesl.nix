{stdenv, curl, fetchgit }:
stdenv.mkDerivation {
  name = "pastesl-git";
  src = fetchgit {
    url = https://github.com/sjau/pastesl.git;
    rev = "e6186d809e826b8fb3d079546ff3f2227a4e7baf";
    sha256 = "1p25brs9qg31cmgmg2di80qdwny7janxfwys8ji9ga1vcrnn2i88";
  };
  installPhase = ''
    mkdir -p $out/bin
    cp -n pastesl $out/bin/

    for i in $out/bin/*; do
      substituteInPlace $i \
        --replace curl ${curl}/bin/curl
    done

  '';
}
