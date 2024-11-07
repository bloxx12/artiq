{
  buildPythonPackage,
  fetchFromGitHub,
  pyserial,
}:
buildPythonPackage rec {
  pname = "asyncserial";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "m-labs";
    repo = "asyncserial";
    rev = version;
    sha256 = "sha256-ZHzgJnbsDVxVcp09LXq9JZp46+dorgdP8bAiTB59K28=";
  };

  propagatedBuildInputs = [pyserial];
}
