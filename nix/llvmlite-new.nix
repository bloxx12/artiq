{
  buildPythonPackage,
  fetchFromGitHub,
  llvm_15,
}:
buildPythonPackage rec {
  pname = "llvmlite";
  version = "0.43.0";

  src = fetchFromGitHub {
    owner = "numba";
    repo = "llvmlite";
    rev = "v${version}";
    sha256 = "sha256-5QBSRDb28Bui9IOhGofj+c7Rk7J5fNv5nPksEPY/O5o=";
  };

  nativeBuildInputs = [llvm_15];

  # Disable static linking
  # https://github.com/numba/llvmlite/issues/93
  postPatch = ''
    substituteInPlace ffi/Makefile.linux --replace "-static-libstdc++" ""
    substituteInPlace llvmlite/tests/test_binding.py --replace "test_linux" "nope"
  '';

  # Set directory containing llvm-config binary
  preConfigure = ''
    export LLVM_CONFIG=${llvm_15.dev}/bin/llvm-config
  '';
}
