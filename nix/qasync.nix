{
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  pyqt6,
  pytestCheckHook,
}:
buildPythonPackage rec {
  pname = "qasync";
  version = "0.27.1";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "CabbageDevelopment";
    repo = "qasync";
    rev = "refs/tags/v${version}";
    sha256 = "sha256-oXzwilhJ1PhodQpOZjnV9gFuoDy/zXWva9LhhK3T00g=";
  };

  buildInputs = [poetry-core];
  propagatedBuildInputs = [pyqt6];

  checkInputs = [pytestCheckHook];
  pythonImportsCheck = ["qasync"];
  disabledTestPaths = ["tests/test_qeventloop.py"];

  postPatch = ''
    rm qasync/_windows.py # Ignoring it is not taking effect and it will not be used on Linux
  '';
}
