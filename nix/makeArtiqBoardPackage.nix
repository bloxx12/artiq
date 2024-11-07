{
  target,
  variant,
  buildCommand ? "python -m artiq.gateware.targets.${target} -V ${variant}",
  experimentalFeatures ? [],
  stdenv,
  rustPlatform,
  python3,
  rust,
  llvmPackages_15,
  llvm_15,
  lld_15,
  vivado,
  migen,
  misoc,
  artiq,
}:
stdenv.mkDerivation {
  name = "artiq-board-${target}-${variant}";
  phases = ["buildPhase" "checkPhase" "installPhase"];
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./artiq/firmware/Cargo.lock;
    outputHashes = {
      "fringe-1.2.1" = "sha256-u7NyZBzGrMii79V+Xs4Dx9tCpiby6p8IumkUl7oGBm0=";
      "tar-no-std-0.1.8" = "sha256-xm17108v4smXOqxdLvHl9CxTCJslmeogjm4Y87IXFuM=";
    };
  };
  nativeBuildInputs = [
    (python3.withPackages (ps: [migen misoc (artiq.withExperimentalFeatures experimentalFeatures) ps.packaging]))
    rust
    llvmPackages_15.clang-unwrapped
    llvm_15
    lld_15
    vivado
    rustPlatform.cargoSetupHook
  ];
  buildPhase = ''
    ARTIQ_PATH=`python -c "import artiq; print(artiq.__path__[0])"`
    ln -s $ARTIQ_PATH/firmware/Cargo.lock .
    cargoSetupPostUnpackHook
    cargoSetupPostPatchHook
    ${buildCommand}
  '';
  doCheck = true;
  checkPhase = ''
    # Search for PCREs in the Vivado output to check for errors
    check_log() {
      grep -Pe "$1" artiq_${target}/${variant}/gateware/vivado.log && exit 1 || true
    }
    check_log "\d+ constraint not met\."
    check_log "Timing constraints are not met\."
  '';
  installPhase = ''
    mkdir $out
    cp artiq_${target}/${variant}/gateware/top.bit $out
    if [ -e artiq_${target}/${variant}/software/bootloader/bootloader.bin ]
    then cp artiq_${target}/${variant}/software/bootloader/bootloader.bin $out
    fi
    if [ -e artiq_${target}/${variant}/software/runtime ]
    then cp artiq_${target}/${variant}/software/runtime/runtime.{elf,fbi} $out
    else cp artiq_${target}/${variant}/software/satman/satman.{elf,fbi} $out
    fi

    mkdir $out/nix-support
    for i in $out/*.*; do
    echo file binary-dist $i >> $out/nix-support/hydra-build-products
    done
  '';
  # don't mangle ELF files as they are not for NixOS
  dontFixup = true;
}
