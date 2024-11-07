{
  mkShell,
  python3,
  llvmPackages_15,
  llvm_15,
  lld_15,
  vivado,
  openocd-bscanspi,
  rust,
  migen,
  misoc,
  artiq,
}:
mkShell {
  name = "artiq-boards-shell";

  buildInputs = [
    (python3.withPackages (ps: [migen misoc artiq ps.packaging ps.paramiko]))

    lld_15
    llvm_15
    llvmPackages_15.clang-unwrapped
    openocd-bscanspi
    rust
    vivado
  ];
}
