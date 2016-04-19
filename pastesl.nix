{stdenv, curl, fetchgit }:
stdenv.mkDerivation {
  name = "pastesl-git";
  src = fetchgit {
    url = https://github.com/sjau/pastesl.git;
    rev = "c133c0241d4c41b99b99dc01c5037f1c6d23bec3";
    sha256 = "0vk8dzjd947cnkvhnfzavm8y2421hrm17kss6qaky59rliaxh095";
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
