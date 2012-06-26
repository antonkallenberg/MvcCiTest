[string]$script:ftpHost
[string]$script:username
[string]$script:password
[System.Net.NetworkCredential]$script:Credential

function Set-FtpConnection {
    param([string]$host, 
          [string]$username, 
          [string]$password)
    
    $script:Credential = New-Object System.Net.NetworkCredential($username, $password) 
	$script:ftpHost  = $host
	$script:username = $username
	$script:password = $password
	
}

function Send-ToFtp {
    param([string]$sourcePath,
		  [string]$targetFolder)

    foreach($item in Get-ChildItem -recurse $sourcePath){ 
		$itemName = [system.io.path]::GetFullPath($item.FullName).SubString([system.io.path]::GetFullPath($sourcePath).Length + 1)
		$fullTargetPath = [system.io.path]::Combine($script:ftpHost+"/$targetFolder/", $itemName)
        if ($item.Attributes -eq "Directory"){
            try{
				$uri = New-Object System.Uri($fullTargetPath)
                $ftpRequest = [System.Net.WebRequest]::Create($uri)
                $ftpRequest.Credentials = $script:Credential
                $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
                $ftpRequest.GetResponse()
            }catch [Net.WebException] {
                Write-Host "$item probably exists ..."
            }
            continue;
        }
		
		$webClient = New-Object System.Net.WebClient
		$webClient.Credentials = $script:Credential
		$uri = New-Object System.Uri($fullTargetPath)
        $webClient.UploadFile($uri, $item.FullName)
    }
}

function Get-FromFtp($sourceFolder, $targetFolder) {

	$fullTargetPath = [system.io.path]::Combine($script:ftpHost, $targetFolder)
    $dirs = Get-FtpDirecoryTree $fullTargetPath
	
	$dirs | Write-Host
	
    <#foreach($dir in $dirs){
       $path = [io.path]::Combine($sourceDestination, $dir)
       
       if ((Test-Path $path) -eq $false) {
          "Creating $path ..."
		  New-Item -Path $path -ItemType Directory | Out-Null
	   }else{
          "Exists $path ..."
       }
    }
    
    $files = Get-FilesTree $ftpUri
    foreach($file in $files){
        $source = [io.path]::Combine($ftpUri, $file)
        $dest = [io.path]::Combine($destination, $file)
        "Downloading $source ..."
        Get-FtpFile $source $dest $user $pass
    }#>
}

function Get-FtpDirecoryTree($ftp) {
    
    $files = New-Object "system.collections.generic.list[string]"
    $folders = New-Object "system.collections.generic.queue[string]"
    $folders.Enqueue($ftp)
    
    while($folders.Count -gt 0) {
        $fld = $folders.Dequeue()
        $newFiles = Get-AllFtpFiles $fld
        $dirs = Get-FtpDirectories $fld
        
        foreach ($line in $dirs){
            $dir = @($newFiles | Where { $line.EndsWith($_) })[0]
            [void]$newFiles.Remove($dir)
            $folders.Enqueue($fld + $dir + "/")
            
            [void]$files.Add($fld.Replace($ftp, "") + $dir + "/")
        }
    }
    
    return ,$files
}

function Get-FtpDirectories($fld) {
    $dirs = New-Object "system.collections.generic.list[string]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $reader = Get-Stream $fld $operation
    while (($line = $reader.ReadLine()) -ne $null) {
       
       if ($line.Trim().ToLower().StartsWith("d") -or $line.Contains(" <DIR> ")) {
            [void]$dirs.Add($line)
        }
    }
    $reader.Dispose();
    
    return ,$dirs
}

function Get-AllFtpFiles($fld) {
    $newFiles = New-Object "system.collections.generic.list[string]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        
    $reader = Get-Stream $fld $operation
    
    while (($line = $reader.ReadLine()) -ne $null) {
       [void]$newFiles.Add($line.Trim()) 
    }
    $reader.Dispose();
    
    return ,$newFiles
}

function Get-Stream($url, $meth) {
	Write-Host "Get-Stream: $url"
    $ftp = [System.Net.WebRequest]::Create($url)
    $ftp.Credentials = $script:Credential
    $ftp.Method = $meth
    $response = $ftp.GetResponse()
    
    return New-Object IO.StreamReader $response.GetResponseStream()
}



Export-ModuleMember Set-FtpConnection, Send-ToFtp, Get-FromFtp