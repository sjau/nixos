{ stdenv, fetchurl, oraclejdk8, swt, pcsclite, callPackage, makeWrapper }:

let swt' = swt.override {jdk = jdk;};
    jdk = oraclejdk8;
    suisse-id = callPackage ./suisseid-pkcs11.nix {};
in
stdenv.mkDerivation rec {
  name = "localsigner-${version}";
  version = "3.1.1";

  src = fetchurl {
    url = "https://www.e-service.admin.ch/wiki/download/attachments/32801435/localsigner_3.1.1_linux.tar.gz?version=1&modificationDate=1430222842000";
    sha256 = "065szy6ihp4rf21bsyv3pgd6pb3rac9ama1imvjadvghkfvwx19a";
    name = "${name}.tar.gz";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    echo $out

    rm lib/swt-*
    rm localsigner.sh
    mkdir -p $out/bin
    cp -r * $out/
    substituteInPlace $out/configuration/drivers.properties --replace /usr/lib/ ${suisse-id}/lib/

    export cp=$out/lib
    export cpath="$cp/localsigner.jar:$cp/JCAPI.jar:$cp/bcprov-jdk15-145.jar:$cp/bcmail-jdk15-145.jar:$cp/bctsp-jdk15-145.jar:${swt'}/jars/swt.jar"

    makeWrapper ${jdk}/bin/java $out/bin/localsigner \
      --add-flags "-Xmx512m -Dbase=$out/ -Djsse.enableSNIExtension=false -classpath $cpath ch.admin.localsigner.main.LocalSigner" \
      --prefix LD_LIBRARY_PATH : "${swt'}/lib:${pcsclite}/lib" \
      --set JAVA_HOME ${jdk}
  '';
}