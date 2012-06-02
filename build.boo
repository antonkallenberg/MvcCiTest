solution_file = "MvcCiTest.sln"
configuration = "release"

target default, (init, compile, copy):
  pass

target init:
  rmdir("build/**")

desc "Compiles the solution"
target compile:
  msbuild(file: solution_file, configuration: configuration)

target copy:
	with FileList("MvcCiTest/**/"):
    .Include("*.{aspx,ascx,config,master,asax,htm,html,css,js,jpg,png,gif}") 
    .ForEach def(file):
      file.CopyToDirectory("build/${configuration}/MvcCiTest")