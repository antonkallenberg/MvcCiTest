Set-ExecutionPolicy bypass
include .\ftp-ls.ps1
include .\util.ps1

properties {
	$label = ([DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss"))
	$configuration = 'Release'
	$environment = 'Debug'
	$specsAssemblyName = "MvcCiTest.Tests.Mspec"
	$cssFilesRoot = "Content"
	$scriptFilesRoot = "Scripts"
	
	$source = '..\MvcCiTest'
	$destinationRoot = "..\..\Deploy\Build"	
	$sln = '..\MvcCiTest.sln'
	$specsRoot = '..\MvcCiTest.Tests.Mspec'
	$tools = '..\tools'
	$backupRoot = "..\..\Deploy\Backup"
	$backupPath = "..\..\Deploy\Backup\$label"
	
	$stagingFtpUri = 'ftp://127.0.0.1:55/'
	$stagingFtpWwwRoot = "$stagingFtpUri/www/"
	$stagingFtpBackupRoot = "$stagingFtpUri/backup/"
	$stagingFtpUser = 'anton'
	$stagingFtpPass = 'anton'
}

task Default -depends CopyFiles

task Staging -depends DeployWebToStagingFtp 

task DeployWebToStagingFtp -depends BackupWebAtStagingFtp {
	$path = Resolve-Path $destinationRoot
	UploadToFtp $path $stagingFtpWwwRoot $stagingFtpUser $stagingFtpPass 
}

task BackupWebAtStagingFtp -depends MergeConfiguration {
	$1 = Resolve-Path $backupPath
	$2 = Resolve-Path $backupRoot
	DownloadFromFtp $1 $stagingFtpWwwRoot $stagingFtpUser $stagingFtpPass
	UploadToFtp $2 $stagingFtpBackupRoot $stagingFtpUser $stagingFtpPass
}

task MergeConfiguration -depends CopyFiles { 
	robocopy "$source\Configurations\$environment\" $destinationRoot /E	
}

task CopyFiles -depends Test {
	robocopy $source $destinationRoot /MIR /XD obj bundler Configurations Properties /XF *.bundle *.coffee *.less *.pdb *.cs *.csproj *.csproj.user *.sln .gitignore README.txt packages.config
}

task Test -depends Compile, Setup { 
	Exec { 
		..\packages\Machine.Specifications.0.5.7\tools\mspec-clr4.exe "$specsRoot\bin\$configuration\$specsAssemblyName.dll" 
	}
}

task Compile -depends Setup { 
	Exec {
		msbuild $sln /t:Clean /t:Build /p:Configuration=$configuration /v:q /nologo	
	}
	&"$source\bundler\node.exe" "$source\bundler\bundler.js" "$source\$cssFilesRoot" "$source\$scriptFilesRoot"
}

task Setup { 
	TryCreateFolder $destinationRoot
	TryCreateFolder $backupRoot
	TryCreateFolder $backupPath
}

task ? -Description "Helper to display task info" {
	Write-Documentation
}