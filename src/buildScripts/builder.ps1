properties {
	$label = ([DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss"))
	$configuration = 'Release'
	$environment = 'Debug'
	$source = '..\MvcCiTest'
	$destinationRoot = "..\..\Build"
	$destination = "$destinationRoot\$label"
	$sln = '..\MvcCiTest.sln'
	$specsRoot = '..\MvcCiTest.Tests.Mspec'
	$specsAssemblyName = "MvcCiTest.Tests.Mspec"
	$cssFilesRoot = "Content"
	$scriptFilesRoot = "Scripts"
}

task Default -depends CopyFiles

task Staging -depends CopyFilesToStagingFtp 

task CopyFilesToStagingFtp  -depends MergeConfiguration {
	Write-Host "copy to ftp"
}

task MergeConfiguration -depends CopyFiles { 
	Exec {
		robocopy "$source\Configurations\$environment\" $destination /E
	}
}

task CopyFiles -depends Test {
	Exec { 
		robocopy $source $destination /MIR /XD obj bundler Configurations Properties /XF *.pdb *.cs *.csproj *.csproj.user *.sln .gitignore README.txt packages.config
	}
}

task Test -depends Compile, Setup { 
	Exec { 
		..\packages\Machine.Specifications.0.5.7\tools\mspec-clr4.exe "$specsRoot\bin\$configuration\$specsAssemblyName.dll" 
	}
}

task Compile -depends Setup { 
	Exec {
		msbuild $sln /t:Clean /t:Build /p:Configuration=$configuration /v:q /nologo
		..\MvcCiTest\bundler\node.exe "$source\bundler\bundler.js" "$source\$cssFilesRoot" "$source\$scriptFilesRoot"
	}
}

task Setup { 
	if ((Test-Path -path $destinationRoot)) {
		dir $destinationRoot -recurse | where {!@(dir -force $_.fullname)} | rm -whatif
		Remove-Item $destinationRoot -Recurse	
	}
	New-Item -Path "$destination" -ItemType "directory"
}

task ? -Description "Helper to display task info" {
	Write-Documentation
}