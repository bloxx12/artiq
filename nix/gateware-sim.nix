{
  stdenvNoCC,
  python3,
  migen,
  misoc,
  artiq,
}:
stdenvNoCC.mkDerivation {
        name = "gateware-sim";
        buildInputs = [
          (python3.withPackages (ps: [migen misoc artiq]))
        ];
        phases = ["buildPhase"];
        buildPhase = ''
          python -m unittest discover -v artiq.gateware.test
          touch $out
        '';
}
