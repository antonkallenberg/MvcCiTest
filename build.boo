solution_file = "MvcCiTest.sln"
configuration = "release"

target default, (init, compile):
  pass

target init:
  rmdir("build")

desc "Compiles the solution"
target compile:
  msbuild(file: solution_file, configuration: configuration)