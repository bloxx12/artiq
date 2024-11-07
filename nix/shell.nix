{
  mkShell,
  artiq-frontend-dev-wrappers,
  libartiq-support,
  qt6,
  vivado,
  vivadoEnv,
  openocd-bscanspi,
  sphinx,
  sphinx-argparse,
  sphinx_rtd_theme,
  pdf2svg,
  latex-artiq-manual,
  migen,
  misoc,
  python3,
  microscope,
  artiq,
  rust,
  llvmPackages_15,
  llvm_15,
  lld_15,
  git,
  lit,
  outputcheck,
  sphinxcontrib-wavedrom,
  sphinxcontrib-tikz,
}:
mkShell {
  name = "artiq-dev-shell";
  buildInputs = [
    (python3.withPackages (ps:
      [
        microscope
        migen
        misoc
        ps.packaging
        ps.paramiko
      ]
      ++ artiq.propagatedBuildInputs))
    artiq-frontend-dev-wrappers
    git
    latex-artiq-manual
    libartiq-support
    lit
    lld_15
    llvm_15
    llvmPackages_15.clang-unwrapped
    openocd-bscanspi
    outputcheck
    pdf2svg
    rust
    sphinx
    sphinx-argparse
    sphinxcontrib-tikz
    sphinxcontrib-wavedrom
    sphinx_rtd_theme
    # To manually run compiler tests:
    # use the vivado-env command to enter a FHS shell that lets you run the Vivado installer
    vivado
    vivadoEnv
  ];
  shellHook = let
    inherit (qt6) qtbase qtsvg;
    inherit (qt6.qtbase.dev) qtPluginPrefix qtQmlPrefix;
  in ''
    export LIBARTIQ_SUPPORT=`libartiq-support`
    export QT_PLUGIN_PATH=${qtbase}/${qtPluginPrefix}:${qtsvg}/${qtPluginPrefix}
    export QML2_IMPORT_PATH=${qtbase}/${qtQmlPrefix}
    export PYTHONPATH=`git rev-parse --show-toplevel`:$PYTHONPATH
  '';
}
