function TryCreateFolder($name){
	if ((Test-Path -path $name)) {
		dir $name -recurse | where {!@(dir -force $_.fullname)} | rm -whatif
		Remove-Item $name -Recurse	
	}
	New-Item -Path $name -ItemType "directory"
}
