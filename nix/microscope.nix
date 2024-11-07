{
  buildPythonPackage,
  fetchFromGitHub,
  migen,
  msgpack,
  prettytable,
  pyserial,
}:
buildPythonPackage {
  pname = "microscope";
  version = "unstable-2020-12-28";
  src = fetchFromGitHub {
    owner = "m-labs";
    repo = "microscope";
    rev = "c21afe7a53258f05bde57e5ebf2e2761f3d495e4";
    sha256 = "sha256-jzyiLRuEf7p8LdhmZvOQj/dyQx8eUE8p6uRlwoiT8vg=";
  };
  propagatedBuildInputs = [pyserial prettytable msgpack migen];
}
