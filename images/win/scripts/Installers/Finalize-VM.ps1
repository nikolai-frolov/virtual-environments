################################################################################
##  File:  Finalize-VM.ps1
##  Desc:  Clean up temp folders after installs to save space
################################################################################

Write-Host "Cleanup WinSxS"
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

Write-Host "Clean up various directories"
@(
    "$env:SystemDrive\Recovery",
    "$env:SystemRoot\logs",
    "$env:SystemRoot\winsxs\manifestcache",
    "$env:SystemRoot\Temp",
    "$env:TEMP"
) | ForEach-Object {
    if (Test-Path $_) {
        Write-Host "Removing $_"
        try {
            takeown /d Y /R /f $_ | Out-Null
            cmd /c "icacls $_ /GRANT:r administrators:F /t /c /q 2>&1" | Out-Null
            Remove-Item $_ -Recurse -Force -ErrorAction Ignore
        } catch { 
            $error.clear()
        }
    }
}

$winInstallDir = "$env:SystemRoot\Installer"
New-Item -Path $winInstallDir -ItemType Directory -Force | Out-Null

# Remove AllUsersAllHosts profile
Remove-Item $profile.AllUsersAllHosts -Force

# Clean yarn and npm cache
yarn cache clean
npm cache clean --force

# allow msi to write to temp folder
# see https://github.com/actions/virtual-environments/issues/1704
try {
    cmd /c "icacls $env:SystemRoot\Temp /grant Users:F /t /c /q 2>&1" | Out-Null
} catch { 
    $error.clear()
}
