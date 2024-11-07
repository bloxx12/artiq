{
  description = "A leading-edge control system for quantum information experiments";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay?ref=snapshot/2024-08-01";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    artiq-comtools = {
      url = "github:m-labs/artiq-comtools";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.sipyco.follows = "sipyco";
    };

    sipyco = {
      url = "github:m-labs/sipyco";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    rust-overlay,
    sipyco,
    artiq-comtools,
  }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [(import rust-overlay)];
    };
    pkgs-aarch64 = import nixpkgs {system = "aarch64-linux";};

    artiqVersionMajor = 9;
    artiqVersionMinor = self.sourceInfo.revCount or 0;
    artiqVersionId = self.sourceInfo.shortRev or "unknown";
    artiqVersion = (builtins.toString artiqVersionMajor) + "." + (builtins.toString artiqVersionMinor) + "+" + artiqVersionId + ".beta";
    artiqRev = self.sourceInfo.rev or "unknown";

    rust = pkgs.rust-bin.nightly."2021-09-01".default.override {
      extensions = ["rust-src"];
      targets = [];
    };

    rustPlatform = pkgs.makeRustPlatform {
      rustc = rust;
      cargo = rust;
    };

    vivadoDeps = let
      # Apply patch from https://github.com/nix-community/nix-environments/pull/54
      # to fix ncurses libtinfo.so's soname issue
      ncurses' = pkgs.ncurses5.overrideAttrs (old: {
        configureFlags = old.configureFlags ++ ["--with-termlib"];
        postFixup = "";
      });
    in
      with pkgs; [
        libxcrypt-legacy
        (ncurses'.override {unicodeSupport = false;})
        zlib
        libuuid
        xorg.libSM
        xorg.libICE
        xorg.libXrender
        xorg.libX11
        xorg.libXext
        xorg.libXtst
        xorg.libXi
        freetype
        fontconfig
      ];

    pythonparser = pkgs.callPackage ./nix/pythonparser.nix {
      # inherit src-pythonparser;
      inherit (pkgs.python3Packages) buildPythonPackage regex;
    };

    qasync = pkgs.callPackage ./nix/qasync.nix {
      inherit (pkgs.python3Packages) buildPythonPackage poetry-core pyqt6 pytestCheckHook;
    };

    libartiq-support = pkgs.callPackage ./nix/libartiq-support.nix {inherit rust;};

    llvmlite-new = pkgs.callPackage ./nix/llvmlite-new.nix {
      inherit (pkgs.python3Packages) buildPythonPackage;
    };

    artiq-upstream = pkgs.callPackage ./nix/artiq-upstream.nix {
      inherit libartiq-support artiqVersion artiqRev llvmlite-new pythonparser;

      inherit (sipyco.packages.x86_64-linux) sipyco;
      inherit (artiq-comtools.packages.x86_64-linux) artiq-comtools;

      inherit (pkgs.python3Packages) buildPythonPackage pyqtgraph pygit2 numpy dateutil scipy prettytable;
      inherit (pkgs.python3Packages) pyserial levenshtein h5py pyqt6 qasync tqdm lmdb jsonschema platformdirs;
    };

    artiq =
      artiq-upstream
      // {
        withExperimentalFeatures = features: artiq-upstream.overrideAttrs (oa: {patches = map (f: ./experimental-features/${f}.diff) features;});
      };

    migen = pkgs.callPackage ./nix/migen.nix {
      inherit (pkgs.python3Packages) buildPythonPackage setuptools colorama;
    };

    asyncserial = pkgs.callPackage ./nix/asasyncserial.nix {
      inherit (pkgs.python3Packages) buildPythonPackage pyserial;
    };

    misoc = pkgs.callPackage ./nix/misoc.nix {
      inherit (pkgs.python3Packages) buildPythonPackage jinja2 numpy migen pyserial asyncserial;
    };

    microscope = pkgs.callPackage ./nix/mimicroscope.nix {
      inherit (pkgs.python3Packages) buildPythonPackage pyserial prettytable msgpack migen;
    };

    vivadoEnv = pkgs.buildFHSEnv {
      name = "vivado-env";
      targetPkgs = vivadoDeps;
    };

    vivado = pkgs.buildFHSEnv {
      name = "vivado";
      targetPkgs = vivadoDeps;
      profile = "set -e; source /opt/Xilinx/Vivado/2022.2/settings64.sh";
      runScript = "vivado";
    };

    artiq-manual-html = pkgs.callPackage ./nix/atartiq-manual-html.nix {
      inherit (self) sourceInfo;
      inherit artiq-comtools artiqVersion artiq-manual-latex;
      inherit (pkgs.python3Packages) sphinx sphinx_rtd_theme sphinxcontrib-tikz sphinx-argparse sphinxcontrib-wavedrom;
    };

    artiq-manual-pdf = pkgs.callPackage ./nix/atartiq-manual-pdf.nix {
      inherit (self) sourceInfo;
      inherit artiq-comtools artiqVersion artiq-manual-latex;
      inherit (pkgs.python3Packages) sphinx sphinx_rtd_theme sphinxcontrib-tikz sphinx-argparse sphinxcontrib-wavedrom;
    };

    artiq-manual-latex = pkgs.texlive.combine {
      inherit
        (pkgs.texlive)
        scheme-basic
        latexmk
        cmap
        collection-fontsrecommended
        fncychap
        titlesec
        tabulary
        varwidth
        framed
        fancyvrb
        float
        wrapfig
        parskip
        upquote
        capt-of
        needspace
        etoolbox
        booktabs
        pgf
        pgfplots
        ;
    };

    makeArtiqBoardPackage = {
      target,
      variant,
      buildCommand ? "python -m artiq.gateware.targets.${target} -V ${variant}",
      experimentalFeatures ? [],
    }:
      pkgs.stdenv.mkDerivation {
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
          (pkgs.python3.withPackages (ps: [migen misoc (artiq.withExperimentalFeatures experimentalFeatures) ps.packaging]))
          rust
          pkgs.llvmPackages_15.clang-unwrapped
          pkgs.llvm_15
          pkgs.lld_15
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
      };

    openocd-bscanspi-f = pkgs: let
      bscan_spi_bitstreams-pkg = pkgs.stdenv.mkDerivation {
        name = "bscan_spi_bitstreams";
        src = pkgs.fetchFromGitHub {
          owner = "quartiq";
          repo = "bscan_spi_bitstreams";
          rev = "01d8f819f15baf9a8cc5d96945a51e4d267ff564";
          sha256 = "1zqv47kzgvbn4c8cr019a6wcja7gn5h1z4kvw5bhpc72fyhagal9";
        };
        phases = ["installPhase"];
        installPhase = ''
          mkdir -p $out/share/bscan-spi-bitstreams
          cp $src/*.bit $out/share/bscan-spi-bitstreams
        '';
      };
    in
      pkgs.buildEnv {
        name = "openocd-bscanspi";
        paths = [pkgs.openocd bscan_spi_bitstreams-pkg];
      };

    artiq-frontend-dev-wrappers =
      pkgs.runCommandNoCC "artiq-frontend-dev-wrappers" {}
      ''
        mkdir -p $out/bin
        for program in ${self}/artiq/frontend/*.py; do
          if [ -x $program ]; then
            progname=`basename -s .py $program`
            outname=$out/bin/$progname
            echo "#!${pkgs.bash}/bin/bash" >> $outname
            echo "exec python3 -m artiq.frontend.$progname \"\$@\"" >> $outname
            chmod 755 $outname
          fi
        done
      '';
  in rec {
    packages.x86_64-linux = {
      default = pkgs.python3.withPackages (ps: [artiq]);
      inherit pythonparser qasync artiq;
      inherit migen misoc asyncserial microscope vivadoEnv vivado;
      inherit artiq-manual-latex artiq-manual-html artiq-manual-pdf;

      openocd-bscanspi = openocd-bscanspi-f pkgs;

      artiq-board-kc705-nist_clock = makeArtiqBoardPackage {
        target = "kc705";
        variant = "nist_clock";
      };
      artiq-board-efc-shuttler = makeArtiqBoardPackage {
        target = "efc";
        variant = "shuttler";
      };
    };

    inherit makeArtiqBoardPackage openocd-bscanspi-f;

    devShells.x86_64-linux = {
      # Main development shell with everything you need to develop ARTIQ on Linux.
      # The current copy of the ARTIQ sources is added to PYTHONPATH so changes can be tested instantly.
      # Additionally, executable wrappers that import the current ARTIQ sources for the ARTIQ frontends
      # are added to PATH.
      default = pkgs.callPackage ./nix/shell.nix {
        inherit libartiq-support artiq-manual-latex rust migen misoc microscope artiq artiq-frontend-dev-wrappers;
        inherit (packages.x86_64-linux) vivadoEnv vivado openocd-bscanspi;
        inherit (pkgs.python3Packages) sphinx sphinx_rtd_theme sphinx-argparse sphinxcontrib-wavedrom sphinxcontrib-tikz;
      };

      # Lighter development shell optimized for building firmware and flashing boards.
      boards = pkgs.callPackage ./nix/shell.nix {
        inherit rust;
        inherit (packages.x86_64-linux) vivado openocd-bscanspi;
      };
    };

    packages.aarch64-linux = {
      openocd-bscanspi = openocd-bscanspi-f pkgs-aarch64;
    };

    hydraJobs = {
      inherit (packages.x86_64-linux) artiq artiq-board-kc705-nist_clock artiq-board-efc-shuttler openocd-bscanspi;

      gateware-sim = pkgs.stdenvNoCC.mkDerivation {
        name = "gateware-sim";
        buildInputs = [
          (pkgs.python3.withPackages (ps: [migen misoc artiq]))
        ];
        phases = ["buildPhase"];
        buildPhase = ''
          python -m unittest discover -v artiq.gateware.test
          touch $out
        '';
      };
      kc705-hitl = pkgs.callPackage ./nix/kc705-hitl.nix {
        inherit (packages.x86_64-linux) openocd-bscanspi artiq artiq-board-kc705-nist_clock;
      };
      inherit artiq-manual-html artiq-manual-pdf;
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "nixbld.m-labs.hk-1:5aSRVA5b320xbNvu30tqxVPXpld73bhtOeH6uAjRyHc=";
    extra-substituters = "https://nixbld.m-labs.hk";
    extra-sandbox-paths = "/opt";
  };
}
