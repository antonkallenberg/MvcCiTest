param(
	[parameter(Mandatory=$false)]
    [alias("e")]
    $Environment
)

function Build() {	
	if([string]::IsNullOrEmpty($Environment) -or $Environment -ieq 'debug') {
		powershell .\src\buildScripts\psake.ps1 ".\src\buildScripts\builder.ps1 -properties @{BuildConfiguration='Debug'}" "Default" "4.0"
	}
	if($Environment -ieq 'staging') {
		powershell .\src\buildScripts\psake.ps1 ".\src\buildScripts\builder.ps1 -properties @{BuildConfiguration='Release'; TargetEnvironment='Staging'}" "Staging" "4.0"
	}
	Write-Host "$Environment build done!"
}

Build