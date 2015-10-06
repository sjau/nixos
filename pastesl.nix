{stdenv, curl, fetchgit }:
stdenv.mkDerivation {
  name = "pastesl-git";
  src = fetchgit {
    url = https://github.com/sjau/pastesl.git;
    rev = "38eda1f273f17007a36dcfb8906f427c970f6bf1";
    sha256 = "02jp2ndf5ixy1gmwp3vzc3zhcbyidqi3p6sx96mp23hw1l0g5rsn";
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
