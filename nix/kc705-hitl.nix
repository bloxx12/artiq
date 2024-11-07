{
  stdenvNoCC,
  artiq,
  python3,
  llvm_15,
  lld_15,
  openssh,
  artiq-board-kc705-nist_clock,
  openocd-bscanspi,
}:
stdenvNoCC.mkDerivation {
  name = "kc705-hitl";

  __networked = true; # compatibility with old patched Nix
  # breaks hydra, https://github.com/NixOS/hydra/issues/1216
  #__impure = true;     # Nix 2.8+

  buildInputs = [
    (python3.withPackages (
      ps:
        [
          artiq
          ps.paramiko
        ]
        ++ ps.paramiko.optional-dependencies.ed25519
    ))
    llvm_15
    lld_15
    openssh
    openocd-bscanspi # for the bscanspi bitstreams
  ];
  phases = ["buildPhase"];
  buildPhase = ''
    export HOME=`mktemp -d`
    mkdir $HOME/.ssh
    cp /opt/hydra_id_ed25519 $HOME/.ssh/id_ed25519
    cp /opt/hydra_id_ed25519.pub $HOME/.ssh/id_ed25519.pub
    echo "rpi-1 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIACtBFDVBYoAE4fpJCTANZSE0bcVpTR3uvfNvb80C4i5" > $HOME/.ssh/known_hosts
    chmod 600 $HOME/.ssh/id_ed25519
    LOCKCTL=$(mktemp -d)
    mkfifo $LOCKCTL/lockctl

    cat $LOCKCTL/lockctl | ${openssh}/bin/ssh \
      -i $HOME/.ssh/id_ed25519 \
      -o UserKnownHostsFile=$HOME/.ssh/known_hosts \
      rpi-1 \
      'mkdir -p /tmp/board_lock && flock /tmp/board_lock/kc705-1 -c "echo Ok; cat"' \
    | (
      # End remote flock via FIFO
      atexit_unlock() {
        echo > $LOCKCTL/lockctl
      }
      trap atexit_unlock EXIT

      # Read "Ok" line when remote successfully locked
      read LOCK_OK

      artiq_flash -t kc705 -H rpi-1 -d ${artiq-board-kc705-nist_clock}
      sleep 30

      export ARTIQ_ROOT=`python -c "import artiq; print(artiq.__path__[0])"`/examples/kc705_nist_clock
      export ARTIQ_LOW_LATENCY=1
      python -m unittest discover -v artiq.test.coredevice
    )

    touch $out
  '';
}
