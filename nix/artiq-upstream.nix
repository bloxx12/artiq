{
  artiq-comtools,
  artiqRev,
  artiqVersion,
  buildPythonPackage,
  cacert,
  dateutil,
  fontconfig,
  h5py,
  jsonschema,
  levenshtein,
  libartiq-support,
  lit,
  lld_15,
  llvm_15,
  llvmlite-new,
  lmdb,
  numpy,
  outputcheck,
  platformdirs,
  prettytable,
  pygit2,
  pyqt6,
  pyqtgraph,
  pyserial,
  pythonparser,
  qasync,
  qt6,
  scipy,
  sipyco,
  tqdm,
}:
buildPythonPackage rec {
  pname = "artiq";
  version = artiqVersion;

  src = ../.;

  preBuild = ''
    export VERSIONEER_OVERRIDE=${version}
    export VERSIONEER_REV=${artiqRev}
  '';

  nativeBuildInputs = [qt6.wrapQtAppsHook];

  # keep llvm_x and lld_x in sync with llvmlite
  propagatedBuildInputs = [
    artiq-comtools
    dateutil
    h5py
    jsonschema
    levenshtein
    lld_15
    llvm_15
    llvmlite-new
    lmdb
    numpy
    platformdirs
    prettytable
    pygit2
    pyqt6
    pyqtgraph
    pyserial
    pythonparser
    qasync
    qt6.qtsvg
    scipy
    sipyco
    tqdm
  ];

  dontWrapQtApps = true;
  postFixup = ''
    wrapQtApp "$out/bin/artiq_dashboard"
    wrapQtApp "$out/bin/artiq_browser"
    wrapQtApp "$out/bin/artiq_session"
  '';

  preFixup = ''
    # Ensure that wrapProgram uses makeShellWrapper rather than makeBinaryWrapper
    # brought in by wrapQtAppsHook. Only makeShellWrapper supports --run.
    wrapProgram() { wrapProgramShell "$@"; }
  '';

  ## Modifies PATH to pass the wrapped python environment (i.e. python3.withPackages(...) to subprocesses.
  ## Allows subprocesses using python to find all packages you have installed
  makeWrapperArgs = [
    ''--run 'if [ ! -z "$NIX_PYTHONPREFIX" ]; then export PATH=$NIX_PYTHONPREFIX/bin:$PATH;fi' ''
    "--set FONTCONFIG_FILE ${fontconfig.out}/etc/fonts/fonts.conf"
  ];

  # FIXME: automatically propagate lld_15 llvm_15 dependencies
  # cacert is required in the check stage only, as certificates are to be
  # obtained from system elsewhere
  nativeCheckInputs = [lld_15 llvm_15 lit outputcheck cacert libartiq-support];
  checkPhase = ''
    python -m unittest discover -v artiq.test

    TESTDIR=`mktemp -d`
    cp --no-preserve=mode,ownership -R $src/artiq/test/lit $TESTDIR
    LIBARTIQ_SUPPORT=`libartiq-support` lit -v $TESTDIR/lit
  '';
}
