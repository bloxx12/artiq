{
  buildPythonPackage,
  colorama,
  fetchFromGitHub,
  setuptools,
}:
buildPythonPackage rec {
  name = "migen";
  version = "0.9.2";
  format = "pyproject";

  src = fetchFromGitHub {
    owner = "m-labs";
    repo = "migen";
    rev = version;
    sha256 = "sha256-9Bj/Qh0/5BVbYrBsLmiX/YTrTKAHB072I0h+YlwMAc8=";
  };

  nativeBuildInputs = [setuptools];
  propagatedBuildInputs = [colorama];
}
