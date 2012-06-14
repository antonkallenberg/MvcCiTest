properties {
  $configuration = "Release"
}

task default -depends CopyFiles

task CopyFiles -depends Test {
	$source = '.\MvcCiTest'
	$destination = '.\Build'
	robocopy $source $destination /MIR /XD obj /XF *.pdb *.cs *.csproj *.csproj.user *.sln .gitignore
}

task Test -depends Compile, Setup { 
  
}

task Compile -depends Setup { 
  msbuild /t:Clean /t:Build /p:Configuration=$configuration /v:q /nologo
  .\MvcCiTest\bundler\node.exe ".\MvcCiTest\bundler\bundler.js" ".\MvcCiTest\Content" ".\MvcCiTest\Scripts"
}

task Setup { 
	if ((Test-Path -path .\Build)) {
		dir '.\Build' -recurse | where {!@(dir -force $_.fullname)} | rm -whatif
		Remove-Item '.\Build' -Recurse	
	}
	New-Item -Path '.\Build' -ItemType "directory"
}

task ? -Description "Helper to display task info" {
	Write-Documentation
}