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
    sha256 = "sha256-p6TgeeaK4NEmbhimEXp31W8hVRo4DgWmcCoqZ+UdN60=";
  };

  doCheck = false;
  propagatedBuildInputs = [regex];
}
