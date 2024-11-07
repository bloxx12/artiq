{
  stdenv,
  rust,
}:
stdenv.mkDerivation {
  name = "libartiq-support";

  src = ../.;
  buildInputs = [rust];

  buildPhase = ''
    rustc $src/artiq/test/libartiq_support/lib.rs -Cpanic=unwind -g
  '';

  installPhase = ''
    mkdir -p $out/lib $out/bin
    cp libartiq_support.so $out/lib
    cat > $out/bin/libartiq-support << EOF
    #!/bin/sh
    echo $out/lib/libartiq_support.so
    EOF
    chmod 755 $out/bin/libartiq-support
  '';
}
