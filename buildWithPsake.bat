powershell -NoProfile -ExecutionPolicy unrestricted -Command "& {Import-Module '.\psake\psake.psm1'; invoke-psake .\default.ps1; }" 