{stdenv, fetchgit, kde4, coreutils, pdftk, recode, unoconv, ghostscript, poppler_utils, tesseract, cuneiform, zip, unzip }:
stdenv.mkDerivation {
  name = "pdfForts-git";
#  src = fetchgit {
#    url = https://github.com/sjau/pdfForts.git;
#    rev = "d4a292bfe369b934e4d014bf58a20e25cf7f2bb4";
#    sha256 = "0giy09fwsdv35801sqrjbrihql88fksk0bl4w351wxibzhgn1vsa";
#  };
    src = /home/hyper/Desktop/git-repos/pdfForts;
  installPhase = ''
    mkdir -p $out/bin
    cp -n **/*.sh $out/bin
    rm $out/bin/vars.sh

    for i in $out/bin/*; do
      substituteInPlace $i \
        --replace /usr/bin/pdfForts/common.sh $out/lib/pdfForts/common.sh \
        --replace /usr/share/kde4/services/ServiceMenus/pdfForts/ $out/share/pdfForts/ \
        --replace kdialog ${kde4.kde_baseapps}/bin/kdialog \
        --replace kate ${kde4.kate}/bin/kate \
        --replace basename ${coreutils}/bin/basename \
        --replace pdftk ${pdftk}/bin/pdftk \
        --replace recode ${recode}/bin/recode \
        --replace unoconv ${unoconv}/bin/unoconv \
        --replace pdftotext ${poppler_utils}/bin/pdftotext \
        --replace tesseract ${tesseract}/bin/tesseract \
        --replace cuneiform ${cuneiform}/bin/cuneiform \
        --replace unzip ${unzip}/bin/unzip \
        --replace " zip " " ${zip}/bin/zip "
    done

    mkdir -p $out/lib/pdfForts
    cp common.sh $out/lib/pdfForts/

    mkdir -p $out/share/kde4/services/ServiceMenus/pdfForts
    cp **/*.desktop $out/share/kde4/services/ServiceMenus/pdfForts/

    for i in $out/share/kde4/services/ServiceMenus/pdfForts/*.desktop; do
      substituteInPlace $i \
        --replace /usr/bin/pdfForts/ $out/bin/
    done

    mkdir -p $out/share/pdfForts
    cp **/*.conf $out/share/pdfForts/
    cp **/*.odt $out/share/pdfForts/
  '';
}

# Problems with GS in
# metaPDF

# Other Problems in
# searchablePDF -> hocr2pdf
# watermarkPDF