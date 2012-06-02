properties {
  $testMessage = 'Executed Test!'
  $compileMessage = 'Executed Compile!'
}

task default -depends CopyFiles

task CopyFiles -depends Test {
	
}

task Test -depends Compile, Setup { 
  $testMessage
}

task Compile -depends Setup { 
  msbuild .\MvcCiTest.sln /p:Configuration=Release
}

task Setup { 
	if ((Test-Path -path .\Build)) {
		Remove-Item .\Build -Recurse	
	}
	New-Item -Path '.\Build ' -ItemType "directory"
}

task ? -Description "Helper to display task info" {
	Write-Documentation
}