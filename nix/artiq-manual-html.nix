{
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
  name = "artiq-manual-html-${version}";
  version = artiqVersion;
  src = ../.;
  buildInputs = [
    sphinx
    sphinx_rtd_theme
    sphinxcontrib-tikz
    sphinx-argparse
    sphinxcontrib-wavedrom
    artiq-manual-latex
    artiq-comtools
    pdf2svg
  ];
  buildPhase = ''
    export VERSIONEER_OVERRIDE=${artiqVersion}
    export SOURCE_DATE_EPOCH=${builtins.toString sourceInfo.lastModified}
    cd doc/manual
    make html
  '';
  installPhase = ''
    cp -r _build/html $out
    mkdir $out/nix-support
    echo doc manual $out index.html >> $out/nix-support/hydra-build-products
  '';
}
