properties {
  $configuration = "Release"
}

task default -depends CopyFiles

task CopyFiles -depends Test {
	$source = '.\MvcCiTest'
	$destination = '.\Build'
	$excludeFiles = @('*.pdb','*.cs','*.csproj','*.csproj.user','*.sln','.gitignore')
	
	$items = get-childitem $source -recurse -exclude $excludeFiles
    foreach ($item in $items)
    {
        $target = join-path $destination $item.FullName.Substring($source.Length)
        $doesTargetExist = -not($item.PSIsContainer -and (test-path($target)));
		if ($doesTargetExist)
        {
            copy-item -path $item.FullName -destination $target
        }
    }
}

task Test -depends Compile, Setup { 
  
}

task Compile -depends Setup { 
  msbuild /t:Clean /t:Build /p:Configuration=$configuration /v:q /nologo
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