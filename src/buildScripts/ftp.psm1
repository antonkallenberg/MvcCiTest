[string]$script:ftpHost
[string]$script:username
[string]$script:password
[System.Net.WebClient]$script:webClient = New-Object System.Net.WebClient

function Set-FtpConnection {
    param([string]$host, 
          [string]$username, 
          [string]$password)
    
    $script:ftpHost  = $host
	$script:username = $username
	$script:password = $password
    $script:webClient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
}

function Send-ToFtp {
    param([string]$sourcePath,
		  [string] $targetFolder)

    foreach($item in Get-ChildItem -recurse $sourcePath){ 
        $fullTargetPath = Get-FullTargetPath $item $sourcePath
        if ($item.Attributes -eq "Directory"){
            try{
                $ftpRequest = [System.Net.WebRequest]::Create($fullTargetPath)
                $ftpRequest.Credentials = New-Object System.Net.NetworkCredential($script:username,$script:password) 
                $ftpRequest.Method = [System.Net.WebRequestMethods+Ftp]::MakeDirectory
                $ftpRequest.GetResponse()
            }catch [Net.WebException] {
                Write-Host "$item.Name probably exists ..."
            }
            continue;
        }
        $script:webClient.UploadFile($fullTargetPath, $item.FullName)
    }
}

function Get-FullTargetPath($item, $sourcePath) {
	$itemName = [system.io.path]::GetFullPath($item.FullName).SubString([system.io.path]::GetFullPath($sourcePath).Length + 1)
	$fullTargetPath = New-Object System.Uri($script:ftpHost+"/$targetFolder/"+$itemName)
	return $fullTargetPath
}

Export-ModuleMember Set-FtpConnection, Send-ToFtp