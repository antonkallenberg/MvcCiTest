Set-ExecutionPolicy Unrestricted
Set-ExecutionPolicy bypass
import-module .\utilities.psm1
import-module .\ftp.psm1

properties {
	$DateLabel = ([DateTime]::Now.ToString("yyyy-MM-dd_HH-mm-ss"))
	
	$BuildConfiguration = 'Debug'
	$TargetEnvironment = 'Debug'
	
	$CssFilesRoot = "Content"
	$WebScriptFilesRoot = "Scripts"
	
	$MspecTestsRoot = '..\MvcCiTest.Tests.Mspec'
	$MspecAssemblyName = "MvcCiTest.Tests.Mspec"
	
	$ApplicationBackupRoot = "..\..\Deploy\Backup"
	$ApplicationBackupRootWithDateLabel = "..\..\Deploy\Backup\$DateLabel"
	
	$BuildOutputDestinationRoot = "..\..\Deploy\Build"	
	$ApplicationSource = '..\MvcCiTest'
	$ApplicationSlnFile = '..\MvcCiTest.sln'
	
	$StagingFtpUri = 'ftp://127.0.0.1:55/'
	$StagingFtpWwwRoot = "www"
	$StagingFtpBackupRoot = "backup"
	$StagingFtpUsername = 'anton'
	$StagingFtpPassword = 'anton'
}

task Default -depends CopyFiles

task Staging -depends DeployWebToStagingFtp 

task DeployWebToStagingFtp -depends BackupWebAtStagingFtp {
	$path = Resolve-Path $BuildOutputDestinationRoot
	#Delete-FromFtp $StagingFtpWwwRoot $StagingFtpUsername $StagingFtpPassword 
	#Upload-ToFtp $path $StagingFtpWwwRoot $StagingFtpUsername $StagingFtpPassword 
    
    #Set-FtpConnection $StagingFtpUri $StagingFtpUsername $StagingFtpPassword
    #Send-ToFtp $path $StagingFtpWwwRoot
}

task BackupWebAtStagingFtp -depends MergeConfiguration {
	$1 = Resolve-Path $ApplicationBackupRootWithDateLabel
	$2 = Resolve-Path $ApplicationBackupRoot
	
	Set-FtpConnection $StagingFtpUri $StagingFtpUsername $StagingFtpPassword
	
	Get-FromFtp $1 $StagingFtpWwwRoot
	#Upload-ToFtp $2 $StagingFtpBackupRoot $StagingFtpUsername $StagingFtpPassword
}

task MergeConfiguration -depends CopyFiles { 
	robocopy "$ApplicationSource\Configurations\$TargetEnvironment\" $BuildOutputDestinationRoot /E	
}

task CopyFiles -depends Test {
	#robocopy $ApplicationSource $BuildOutputDestinationRoot /MIR /XD obj bundler Configurations Properties /XF *.bundle *.coffee *.less *.pdb *.cs *.csproj *.csproj.user *.sln .gitignore README.txt packages.config
}

task Test -depends Compile, Setup { 
	Exec { 
		..\packages\Machine.Specifications.0.5.7\tools\mspec-clr4.exe "$MspecTestsRoot\bin\$BuildConfiguration\$MspecAssemblyName.dll" 
	}
}

task Compile -depends Setup { 
	Exec {
		msbuild $ApplicationSlnFile /t:Clean /t:Build /p:Configuration=$BuildConfiguration /v:q /nologo	
	}
	&"$ApplicationSource\bundler\node.exe" "$ApplicationSource\bundler\bundler.js" "$ApplicationSource\$CssFilesRoot" "$ApplicationSource\$WebScriptFilesRoot"
}

task Setup { 
	Add-FolderIfMissing $BuildOutputDestinationRoot
	if (!($TargetEnvironment -ieq 'debug')) {
		Add-FolderIfMissing $ApplicationBackupRoot
		Add-FolderIfMissing $ApplicationBackupRootWithDateLabel
	}
}

task ? -Description "Helper to display task info" {
	Write-Documentation
}