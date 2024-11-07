{
  src-migen,
  buildPythonPackage,
  colorama,
  setuptools,
}:
buildPythonPackage {
  name = "migen";
  format = "pyproject";

  src = src-migen;

  nativeBuildInputs = [setuptools];
  propagatedBuildInputs = [colorama];
}
