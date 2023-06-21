<#
.SYNOPSIS
    Script: OneDrive Storage Sense
.DESCRIPTION
    This script compares the OneDrive registry entries with the Storage Sense settings
    and creates registry keys for mismatched values.
.NOTES
    Author: Mir Rayhan
    Created: June 16, 2023
    Version: 1.0
#>



function CreateRegistryKeys($mismatchedValues, $prefix) {
    foreach ($value in $mismatchedValues) {
        $newRegistryKeyPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'  # Specify the path for the new registry key
        $newRegistryKeyName = "$prefix$value"

        # Create the new registry key
        New-Item -Path $newRegistryKeyPath -Name $newRegistryKeyName -Force
        #Write-Host "Registry key '$newRegistryKeyName' has been created in '$newRegistryKeyPath'."

        # Set the REG_DWORD value for the new registry key
        Set-ItemProperty -Path "$newRegistryKeyPath\$newRegistryKeyName" -Name '02' -Value '1' -Type DWORD
        Set-ItemProperty -Path "$newRegistryKeyPath\$newRegistryKeyName" -Name '128' -Value '14' -Type DWORD
        #Write-Host "Registry value '$newRegistryValueName' with data '$newRegistryValueData' has been created in '$newRegistryKeyPath\$newRegistryKeyName'."
    }
}


# Get the temporary directory path for the current user session
$tempPath = $env:TEMP
$User = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$oneDriveListFile = Join-Path $tempPath 'OneDrive-List.txt'
$prefix = "OneDrive!$User!Business1|"
$OneDrive = Test-Path 'HKCU:\Software\SyncEngines\Providers\OneDrive'
$ssPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy'

if ($OneDrive) {
    $registryPath = 'HKCU:\Software\SyncEngines\Providers\OneDrive'

    $outputFile = Join-Path $tempPath -ChildPath 'OneDrive-List.txt'  # Specify the path and filename for the output text file
    #Write-Host $outputFile
    $registryEntries = Get-ChildItem -Path $registryPath | Where-Object { $_.PSChildName -notlike 'Business*' } | Select-Object -ExpandProperty PSChildName

    if ($registryEntries) {
        $registryEntries | Out-File -FilePath $outputFile -Encoding UTF8
        #Write-Host 'List of created registry entries (excluding "Business") has been created.'
        $oneDriveContent = Get-Content $outputFile
        CreateRegistryKeys $oneDriveContent $prefix
    } else {
        #Write-Host 'No registry entries (excluding "Business") found.'
    }
}