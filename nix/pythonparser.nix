{
  buildPythonPackage,
  fetchFromGitHub,
  regex,
}:
buildPythonPackage rec {
  pname = "pythonparser";
  version = "1.4";

  # src = src-pythonparser;
  src = fetchFromGitHub {
    owner = "m-labs";
    repo = "pythonparser";
    rev = version;
    sha256 = "";
  };

  doCheck = false;
  propagatedBuildInputs = [regex];
}
