{
  buildPythonPackage,
  jinja2,
  numpy,
  migen,
  pyserial,
  asyncserial,
  fetchFromGitHub,
}:
buildPythonPackage rec {
  name = "misoc";
  version = "0.12";

  src = fetchFromGitHub {
    owner = "m-labs";
    repo = "misoc";
    rev = version;
    fetchSubmodules = true;
  };

  propagatedBuildInputs = [
    jinja2
    numpy
    migen
    pyserial
    asyncserial
  ];
}
