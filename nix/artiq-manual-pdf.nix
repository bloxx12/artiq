{
  artiq,
  artiq-comtools,
  artiqVersion,
  artiq-manual-latex,
  pdf2svg,
  sourceInfo,
  sphinx,
  sphinx-argparse,
  sphinxcontrib-tikz,
  sphinxcontrib-wavedrom,
  sphinx_rtd_theme,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  name = "artiq-manual-pdf-${version}";
  version = artiqVersion;
  src = ../.;
  buildInputs = [
    sphinx
    sphinx_rtd_theme
    sphinxcontrib-tikz
    sphinx-argparse
    sphinxcontrib-wavedrom
    pdf2svg
    artiq-manual-latex
    artiq-comtools
  ];
  buildPhase = ''
    export VERSIONEER_OVERRIDE=${artiq.version}
    export SOURCE_DATE_EPOCH=${builtins.toString sourceInfo.lastModified}
    cd doc/manual
    make latexpdf
  '';
  installPhase = ''
    mkdir $out
    cp _build/latex/ARTIQ.pdf $out
    mkdir $out/nix-support
    echo doc-pdf manual $out ARTIQ.pdf >> $out/nix-support/hydra-build-products
  '';
}
