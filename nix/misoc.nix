{
  buildPythonPackage,
  src-misoc,
  jinja2,
  numpy,
  migen,
  pyserial,
  asyncserial,
}:
buildPythonPackage {
  name = "misoc";

  src = src-misoc;

  propagatedBuildInputs = [
    jinja2
    numpy
    migen
    pyserial
    asyncserial
  ];
}
