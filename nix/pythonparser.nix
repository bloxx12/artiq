{
  buildPythonPackage,
  src-pythonparser,
  regex,
}:
buildPythonPackage {
  pname = "pythonparser";
  version = "1.4";

  src = src-pythonparser;

  doCheck = false;
  propagatedBuildInputs = [regex];
}
