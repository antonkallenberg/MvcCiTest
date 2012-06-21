param(
	[parameter(Mandatory=$false)]
    [alias("e")]
    $Environment
)

function build() {
	if([string]::IsNullOrEmpty($Environment) -or $Environment -ieq 'debug') {
		powershell .\src\buildScripts\psake.ps1 ".\src\buildScripts\builder.ps1 -properties @{configuration='Debug'}" "Default" "4.0"
	}
	if($Environment -ieq 'staging') {
		powershell .\src\buildScripts\psake.ps1 ".\src\buildScripts\builder.ps1 -properties @{configuration='Release'; environment='Staging'}" "Staging" "4.0"
	}
	Write-Host "$Environment build done!"
}

build