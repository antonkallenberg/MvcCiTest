#public
function Upload-ToFtp($artifacts, $ftpUri, $user, $pass) {
    $webclient = New-Object System.Net.WebClient 
    $webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass)  

	Write-Host $artifacts
    foreach($item in Get-ChildItem -recurse $artifacts){ 
        $relpath = [system.io.path]::GetFullPath($item.FullName).SubString([system.io.path]::GetFullPath($artifacts).Length + 1)

        if ($item.Attributes -eq "Directory"){
            try{
                Write-Host Creating $item.Name
                
                $makeDirectory = [System.Net.WebRequest]::Create($ftpUri+$relpath);
                $makeDirectory.Credentials = New-Object System.Net.NetworkCredential($user,$pass) 
                $makeDirectory.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory;
                $makeDirectory.GetResponse();
            }catch [Net.WebException] {
                Write-Host $item.Name probably exists ...
            }
            continue;
        }
        "Uploading $item..."
        $uri = New-Object System.Uri($ftpUri+$relpath) 
        $webclient.UploadFile($uri, $item.FullName)
    }
}

function Download-FromFtp($destination, $ftpUri, $user, $pass) {
    $dirs = Get-DirecoryTree $ftpUri $user $pass
    foreach($dir in $dirs){
       $path = [io.path]::Combine($destination, $dir)
       
       if ((Test-Path $path) -eq $false) {
          "Creating $path ..."
		  New-Item -Path $path -ItemType Directory | Out-Null
	   }else{
          "Exists $path ..."
       }
    }
    
    $files = Get-FilesTree $ftpUri $user $pass
    foreach($file in $files){
        $source = [io.path]::Combine($ftpUri, $file)
        $dest = [io.path]::Combine($destination, $file)
        "Downloading $source ..."
        Get-FtpFile $source $dest $user $pass
    }
}

function Delete-FromFtp($ftpUri, $userName, $password) {
	Write-Host "Delete-FromFtp cred: $userName - $password"
	$fileTree = Get-FilesTree $ftpUri $userName $password
	if($fileTree -gt 0){
		foreach($file in $fileTree) {
			$ftpFile = [io.path]::Combine($ftpUri, $file)
			Delete-FtpFile $ftpFile $userName $password
		}
	}
	$dirTree = [array](Get-DirecoryTree $ftpUri $userName $password) | sort -Property @{ Expression = {$_.Split('/').Count} } -Desc
	if($dirTree -gt 0) {
		foreach($dir in $dirTree){
			$ftpDir = [io.path]::Combine($ftpUri, $dir)
			$ftpDir
			Delete-Directory $ftpDir $userName $password
		}
	}
}

#private
function Delete-FtpFile ($source, $userName, $password) { 
	Write-Host " deleting $source..."
	Write-Host "Delete-FtpFile cred: $userName - $password"
	$ftpRequest = [System.Net.FtpWebRequest]::create($source) 
	$ftpRequest.Credentials = New-Object System.Net.NetworkCredential($userName, $password) 
	$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile 
	$ftpRequest.UseBinary = $true 
	$ftpRequest.KeepAlive = $false 
	
	$ftpResponse = $ftpRequest.GetResponse()
	"Delete status: {0}" -f $ftpResponse.StatusDescription
}

function Delete-Directory($source, $userName, $password) { 
	Write-Host " deleting $source..."
	$ftpRequest = [System.Net.FtpWebRequest]::create($source) 
	$ftpRequest.Credentials = New-Object System.Net.NetworkCredential($userName, $password) 
	$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::RemoveDirectory 
	$ftpRequest.UseBinary = $true 
	$ftpRequest.KeepAlive = $false 
	
	$ftpResponse = $ftpRequest.GetResponse()
	"Delete status: {0}" -f $ftpResponse.StatusDescription
}

function Get-FtpFile($source, $target, $userName, $password) { 
	$ftpRequest = [System.Net.FtpWebRequest]::create($source) 
	$ftpRequest.Credentials = New-Object System.Net.NetworkCredential($userName, $password) 
	$ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile 
	$ftpRequest.UseBinary = $true 
	$ftpRequest.KeepAlive = $false 

	$ftpResponse = $ftpRequest.GetResponse() 
	$responseStream = $ftpResponse.GetResponseStream() 

	$targetFile = New-Object IO.FileStream ($target,[IO.FileMode]::Create) 
	[byte[]]$readBuffer = New-Object byte[] 1024 

	do{ 
		$readLength = $responseStream.Read($readBuffer,0,1024) 
		$targetFile.Write($readBuffer,0,$readLength) 
	} 
	while ($readLength -ne 0) 

	$targetFile.close() 
} 

function Get-DirecoryTree($ftp, $user, $pass) {
    $creds = New-Object System.Net.NetworkCredential($user, $pass)
    $files = New-Object "system.collections.generic.list[string]"
    $folders = New-Object "system.collections.generic.queue[string]"
    $folders.Enqueue($ftp)
    
    while($folders.Count -gt 0) {
        $fld = $folders.Dequeue()
        $newFiles = Get-AllFiles $creds $fld
        $dirs = Get-Directories $creds $fld
        
        foreach ($line in $dirs){
            $dir = @($newFiles | Where { $line.EndsWith($_) })[0]
            [void]$newFiles.Remove($dir)
            $folders.Enqueue($fld + $dir + "/")
            
            [void]$files.Add($fld.Replace($ftp, "") + $dir + "/")
        }
    }
    
    return ,$files
}

function Get-FilesTree($ftp, $userName, $password) {
	Write-Host "Get-FilesTree cred: $userName - $password"
    $creds = New-Object System.Net.NetworkCredential($userName, $password)
    $files = New-Object "system.collections.generic.list[string]"
    $folders = New-Object "system.collections.generic.queue[string]"
    $folders.Enqueue($ftp)
    
    while($folders.Count -gt 0){
        $fld = $folders.Dequeue()
        
        $newFiles = Get-AllFiles $creds $fld
        $dirs = Get-Directories $creds $fld
        
        foreach ($line in $dirs){
            $dir = @($newFiles | Where { $line.EndsWith($_) })[0]
            [void]$newFiles.Remove($dir)
            $folders.Enqueue($fld + $dir + "/")
        }
        
        $newFiles | ForEach-Object { 
            $files.Add($fld.Replace($ftp, "") + $_) 
        }
    }
    
    return ,$files
}

function Get-Directories($creds, $fld) {
    $dirs = New-Object "system.collections.generic.list[string]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    $reader = Get-Stream $creds $fld $operation
    while (($line = $reader.ReadLine()) -ne $null) {
       
       if ($line.Trim().ToLower().StartsWith("d") -or $line.Contains(" <DIR> ")) {
            [void]$dirs.Add($line)
        }
    }
    $reader.Dispose();
    
    return ,$dirs
}

function Get-AllFiles($creds, $fld) {
    $newFiles = New-Object "system.collections.generic.list[string]"
    $operation = [System.Net.WebRequestMethods+Ftp]::ListDirectory
        
    $reader = Get-Stream $creds $fld $operation
    
    while (($line = $reader.ReadLine()) -ne $null) {
       [void]$newFiles.Add($line.Trim()) 
    }
    $reader.Dispose();
    
    return ,$newFiles
}

function Get-Stream($creds, $url, $meth) {
    $ftp = [System.Net.WebRequest]::Create($url)
    $ftp.Credentials = $creds
    $ftp.Method = $meth
    $response = $ftp.GetResponse()
    
    return New-Object IO.StreamReader $response.GetResponseStream()
}

Export-ModuleMember Upload-ToFtp, Download-FromFtp, Delete-FromFtp