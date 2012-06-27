[string]$script:ftpHost
[string]$script:username
[string]$script:password
[System.Net.NetworkCredential]$script:Credentials

function Set-FtpConnection {
    param([string]$host, 
          [string]$username, 
          [string]$password)
    
    $script:Credentials = New-Object System.Net.NetworkCredential($username, $password) 
	$script:ftpHost  = $host
	$script:username = $username
	$script:password = $password	
}

function Send-ToFtp {
    param([string]$sourcePath,
		  [string]$ftpFolder)

    foreach($item in Get-ChildItem -recurse $sourcePath){ 
		$itemName = [System.IO.Path]::GetFullPath($item.FullName).SubString([System.IO.Path]::GetFullPath($sourcePath).Length + 1)
		$fullFtpPath = [System.IO.Path]::Combine($script:ftpHost+"/$ftpFolder/", $itemName)
        if ($item.Attributes -eq "Directory"){
            try{
				$uri = New-Object System.Uri($fullFtpPath)
                $fullFtpPathRequest = [System.Net.WebRequest]::Create($uri)
                $fullFtpPathRequest.Credentials = $script:Credentials
                $fullFtpPathRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
                $fullFtpPathRequest.GetResponse()
            }catch [Net.WebException] {
                Write-Host "$item probably exists ..."
            }
            continue;
        }
		
		$webClient = New-Object System.Net.WebClient
		$webClient.Credentials = $script:Credentials
		$uri = New-Object System.Uri($fullFtpPath)
        $webClient.UploadFile($uri, $item.FullName)
    }
}

function Get-FromFtp {
	param([string]$sourceFolder, 
		  [string]$ftpFolder)
		   
	$fullFtpPath = [System.IO.Path]::Combine($script:ftpHost, $ftpFolder)
    $dirs = Get-FtpDirecoryTree $fullFtpPath
	foreach($dir in $dirs){
       $path = [io.path]::Combine($sourceFolder, $dir)
       if ((Test-Path $path) -eq $false) {
		  New-Item -Path $path -ItemType Directory | Out-Null
	   }
    }
    $files = Get-FtpFilesTree $fullFtpPath
	foreach($file in $files){
        $ftpPath = $fullFtpPath + "/" + $file
        $localFilePath = [io.path]::Combine($sourceFolder, $file)
        Write-Host "Downloading $ftpPath ..."
        Get-FtpFile $ftpPath $localFilePath
    }
}


function Get-FtpDirecoryTree($fullFtpPath) {    
	if($fullFtpPath.EndsWith("/") -eq $false) {
		$fullFtpPath = $fullFtpPath += "/"
	}
	
	$folderTree = New-Object "System.Collections.Generic.List[string]"
    $folders = New-Object "System.Collections.Generic.Queue[string]"
    $folders.Enqueue($fullFtpPath)
    while($folders.Count -gt 0) {
        $folder = $folders.Dequeue()
        $directoryContent = Get-FtpDirectoryContent $folder		
        $dirs = Get-FtpDirectories $folder
        foreach ($line in $dirs){
            $dir = @($directoryContent | Where { $line.EndsWith($_) })[0]
            [void]$directoryContent.Remove($dir)
			$folders.Enqueue($folder + $dir + "/")
            $folderTree.Add($folder.Replace($fullFtpPath, "") + $dir + "/")
        }
    }
    return $folderTree
}

function Get-FtpFilesTree($fullFtpPath) {
	if($fullFtpPath.EndsWith("/") -eq $false) {
		$fullFtpPath = $fullFtpPath += "/"
	}
    
    $fileTree = New-Object "System.Collections.Generic.List[string]"
    $folders = New-Object "System.Collections.Generic.Queue[string]"
    $folders.Enqueue($fullFtpPath)
    while($folders.Count -gt 0){
        $folder = $folders.Dequeue()
        $directoryContent = Get-FtpDirectoryContent $folder
        $dirs = Get-FtpDirectories $folder
        foreach ($line in $dirs){
            $dir = @($directoryContent | Where { $line.EndsWith($_) })[0]
            [void]$directoryContent.Remove($dir)
            $folders.Enqueue($folder + $dir + "/")
        }
        $directoryContent | ForEach { 
            $fileTree.Add($folder.Replace($fullFtpPath, "") + $_) 
        }
    }
    
	Write-Host $fileTree.count
    return $fileTree
}

function Get-FtpDirectories($folder) {
    $dirs = New-Object "system.collections.generic.list[string]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $reader = Get-Stream $folder $operation
    while (($line = $reader.ReadLine()) -ne $null) {
       if ($line.Trim().ToLower().StartsWith("d") -or $line.Contains(" <DIR> ")) {
            $dirs.Add($line)
        }
    }
    $reader.Dispose();
    return ,$dirs
}

function Get-FtpDirectoryContent($folder) {
    $files = New-Object "System.Collections.Generic.List[String]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectory
    $reader = Get-Stream $folder $operation
    while (($line = $reader.ReadLine()) -ne $null) {
       $files.Add($line.Trim()) 
    }
    $reader.Dispose();
    return ,$files
}

function Get-FtpFile($ftpPath, $localFilePath) { 
	$ftpRequest = [System.Net.FtpWebRequest]::create($ftpPath) 
	$ftpRequest.Credentials = $script:Credentials
	$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile 
	$ftpRequest.UseBinary = $true 
	$ftpRequest.KeepAlive = $false 
	$ftpResponse = $ftpRequest.GetResponse() 
	$responseStream = $ftpResponse.GetResponseStream() 
	
	[byte[]]$readBuffer = New-Object byte[] 1024
	$targetFile = New-Object IO.FileStream ($localFilePath, [IO.FileMode]::Create) 
	while ($readLength -ne 0) { 
		$readLength = $responseStream.Read($readBuffer,0,1024) 
		$targetFile.Write($readBuffer,0,$readLength) 
	} 
	
	$targetFile.close() 
} 

function Get-Stream($url, $meth) {
    $fullFtpPath = [System.Net.WebRequest]::Create($url)
    $fullFtpPath.Credentials = $script:Credentials
    $fullFtpPath.Method = $meth
    $response = $fullFtpPath.GetResponse()
    return New-Object IO.StreamReader $response.GetResponseStream()
}

Export-ModuleMember Set-FtpConnection, Send-ToFtp, Get-FromFtp