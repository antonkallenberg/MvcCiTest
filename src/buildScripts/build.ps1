properties {
  $configuration = 'Release'
  $source = '..\MvcCiTest'
  $destination = '..\..\Build'
  $sln = '..\MvcCiTest.sln'
  $specsBaseDir = '..\MvcCiTest.Tests.Mspec' 
}

task default -depends CopyFiles

task CopyFiles -depends Test {
	robocopy $source $destination /MIR /XD obj /XF *.pdb *.cs *.csproj *.csproj.user *.sln .gitignore
}

task Test -depends Compile, Setup { 
	exec { ..\packages\Machine.Specifications.0.5.7\tools\mspec-clr4.exe "$specsBaseDir\bin\$configuration\MvcCiTest.Tests.Mspec.dll" }
}

task Compile -depends Setup { 
  msbuild $sln /t:Clean /t:Build /p:Configuration=$configuration /v:q /nologo
  ..\MvcCiTest\bundler\node.exe "$source\bundler\bundler.js" "$source\Content" "$source\Scripts"
}

task Setup { 
	if ((Test-Path -path $destination)) {
		dir $destination -recurse | where {!@(dir -force $_.fullname)} | rm -whatif
		Remove-Item $destination -Recurse	
	}
	New-Item -Path $destination -ItemType "directory"
}

task ? -Description "Helper to display task info" {
	Write-Documentation
}