param(
    [Parameter(Mandatory=$false)]
    [string]$CabFilePath
)

$vendor = -join (83,97,109,115,117,110,103 | ForEach-Object { [char]$_ }) 
$service1 = -join (83,121,115,116,101,109 | ForEach-Object { [char]$_ }) 
$service2 = -join (83,117,112,112,111,114,116 | ForEach-Object { [char]$_ })
$service3 = -join (69,110,103,105,110,101 | ForEach-Object { [char]$_ })
$exeName = "$vendor$service1$service2$service3.exe"
$appAcronym = -join (83,83,83,69 | ForEach-Object { [char]$_ })  # SSSE
$innerCabName = -join (115,101,116,116,105,110,103,115,95,120,54,52,46,99,97,98 | ForEach-Object { [char]$_ })  # settings_x64.cab

$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted") {
    Write-Host "PowerShell execution policy is restricted. Run this command first:" -ForegroundColor Red
    Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
    return
}

if (-not $CabFilePath) {
    Write-Host "Enter the full path to the CAB file you want to process:" -ForegroundColor Cyan
    $CabFilePath = Read-Host "CAB file path"
    
    if (-not $CabFilePath) {
        Write-Error "No CAB file path provided"
        return
    }
}

$originalPattern = @(0x00, 0x4C, 0x8B, 0xF0, 0x48, 0x83, 0xF8, 0xFF, 0x0F, 0x85, 0x8A, 0x00, 0x00, 0x00, 0xFF, 0x15)
$targetPattern = @(0x00, 0x4C, 0x8B, 0xF0, 0x48, 0x83, 0xF8, 0xFF, 0x48, 0xE9, 0x8A, 0x00, 0x00, 0x00, 0xFF, 0x15)

function Find-BytePattern {
    param(
        [byte[]]$FileBytes,
        [byte[]]$Pattern
    )
    
    for ($i = 0; $i -le ($FileBytes.Length - $Pattern.Length); $i++) {
        $match = $true
        for ($j = 0; $j -lt $Pattern.Length; $j++) {
            if ($FileBytes[$i + $j] -ne $Pattern[$j]) {
                $match = $false
                break
            }
        }
        if ($match) {
            return $i
        }
    }
    return -1
}

try {
    $CabFilePath = $CabFilePath.Trim('"')  # Remove quotes if present
    
    if (-not (Test-Path $CabFilePath)) {
        Write-Host "CAB file not found: $CabFilePath" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please check:" -ForegroundColor Yellow
        Write-Host "1. The CAB file path is correct" -ForegroundColor White
        Write-Host "2. The CAB file exists" -ForegroundColor White
        Write-Host "3. You have access to the CAB file" -ForegroundColor White
        Write-Host ""
        Write-Host "Current directory: $PWD" -ForegroundColor Cyan
        Write-Host "CAB files in current directory:" -ForegroundColor Cyan
        Get-ChildItem -Path . -Filter "*.cab" | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor White }
        return
    }
    
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $extractDir = Join-Path -Path $PSScriptRoot -ChildPath "CAB_Extract_$timestamp"
    $level1Dir = Join-Path -Path $extractDir -ChildPath "Level1"
    $level2DirName = "Level2_" + $innerCabName.Replace('.cab', '')
    $level2Dir = Join-Path -Path $extractDir -ChildPath $level2DirName
    $finalDir = Join-Path -Path $PSScriptRoot -ChildPath "$($vendor)_$($appAcronym)_Patched_$timestamp"
    New-Item -Path $level1Dir -ItemType Directory -Force | Out-Null
    New-Item -Path $level2Dir -ItemType Directory -Force | Out-Null
    New-Item -Path $finalDir -ItemType Directory -Force | Out-Null 
    Write-Host "Created extraction directories:" -ForegroundColor Green
    Write-Host "  Level 1: $level1Dir" -ForegroundColor Cyan
    Write-Host "  Level 2: $level2Dir" -ForegroundColor Cyan
    Write-Host "  Final: $finalDir" -ForegroundColor Green
    Write-Host ""
    Write-Host "Extracting main CAB file..." -ForegroundColor Yellow
    $expandResult = & expand.exe "$CabFilePath" -F:* "$level1Dir" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to extract main CAB file: $expandResult"
        return
    }
    
    Write-Host "✓ Main CAB extraction complete" -ForegroundColor Green
    
    $level1Files = Get-ChildItem -Path $level1Dir -Recurse -File
    Write-Host ""
    Write-Host "Files in main CAB:" -ForegroundColor Cyan
    $level1Files | ForEach-Object {
        $fileSize = [math]::Round($_.Length / 1KB, 2)
        Write-Host "  $($_.Name) ($fileSize KB)" -ForegroundColor White
    }
    
    $settingsCab = $level1Files | Where-Object { $_.Name -eq $innerCabName }
    
    if (-not $settingsCab) {
        Write-Host ""
        Write-Host "$innerCabName not found!" -ForegroundColor Red
        Write-Host "Available CAB files:" -ForegroundColor Yellow
        $level1Files | Where-Object { $_.Extension -eq ".cab" } | ForEach-Object {
            Write-Host "  $($_.Name)" -ForegroundColor White
        }
        
        if ($level1Files | Where-Object { $_.Extension -eq ".cab" }) {
            Write-Host ""
            Write-Host "Found other CAB files. Do you want to extract all of them? (Y/n)" -ForegroundColor Yellow
            $extractAll = Read-Host
            if ($extractAll -ne 'n' -and $extractAll -ne 'N') {
                $cabFiles = $level1Files | Where-Object { $_.Extension -eq ".cab" }
                foreach ($cab in $cabFiles) {
                    Write-Host "Extracting: $($cab.Name)..." -ForegroundColor Yellow
                    $cabExtractDir = Join-Path -Path $level2Dir -ChildPath $cab.BaseName
                    New-Item -Path $cabExtractDir -ItemType Directory -Force | Out-Null
                    $cabExpandResult = & expand.exe "$($cab.FullName)" -F:* "$cabExtractDir" 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "✓ Extracted: $($cab.Name)" -ForegroundColor Green
                    } else {
                        Write-Host "Failed to extract: $($cab.Name)" -ForegroundColor Red
                    }
                }
            }
        } else {
            Write-Host "No CAB files found to extract further." -ForegroundColor Red
            return
        }
    } else {
        # Extract inner CAB
        Write-Host ""
        Write-Host "Extracting $innerCabName..." -ForegroundColor Yellow
        $settingsExpandResult = & expand.exe "$($settingsCab.FullName)" -F:* "$level2Dir" 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to extract $innerCabName : $settingsExpandResult"
            return
        }
        
        Write-Host "✓ $innerCabName extraction complete" -ForegroundColor Green
    }
    
    $level2Files = Get-ChildItem -Path $level2Dir -Recurse -File
    Write-Host ""
    Write-Host "Files extracted from inner CAB(s):" -ForegroundColor Cyan
    $level2Files | ForEach-Object {
        $fileSize = [math]::Round($_.Length / 1KB, 2)
        Write-Host "  $($_.Name) ($fileSize KB)" -ForegroundColor White
    }
    
    $ssseFile = $level2Files | Where-Object { $_.Name -eq $exeName }
    
    if (-not $ssseFile) {
        Write-Host ""
        Write-Host "$exeName not found!" -ForegroundColor Red
        Write-Host "Available executables:" -ForegroundColor Yellow
        $level2Files | Where-Object { $_.Extension -eq ".exe" } | ForEach-Object {
            Write-Host "  $($_.Name)" -ForegroundColor White
        }
        return
    }
    
    Write-Host ""
    Write-Host "Found $exeName!" -ForegroundColor Green
    Write-Host "File size: $([math]::Round($ssseFile.Length / 1KB, 2)) KB" -ForegroundColor Cyan
    
    # Copy all Level 2 files to final directory first
    Write-Host ""
    Write-Host "Copying all files to final directory..." -ForegroundColor Yellow
    foreach ($file in $level2Files) {
        $destPath = Join-Path -Path $finalDir -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destPath -Force
    }
    Write-Host "✓ All files copied to: $finalDir" -ForegroundColor Green
    
    # Now work with the target file in the final directory
    $FilePath = Join-Path -Path $finalDir -ChildPath $exeName
    
    $backupPath = "$FilePath.backup"
    Copy-Item $FilePath $backupPath -Force
    Write-Host "Backup created: $backupPath" -ForegroundColor Green
    
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)
    Write-Host "File size: $($fileBytes.Length) bytes" -ForegroundColor Cyan
    
    $patchedOffset = Find-BytePattern -FileBytes $fileBytes -Pattern $targetPattern
    if ($patchedOffset -ne -1) {
        Write-Host ""
        Write-Host "File appears to already be patched!" -ForegroundColor Green
        Write-Host "Target pattern found at offset: 0x$($patchedOffset.ToString('X8'))" -ForegroundColor Yellow
        Write-Host "Patched bytes: $(($targetPattern | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor Green
        
        Write-Host ""
        $response = Read-Host "Do you want to revert the patch? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            # Revert patch - swap the patterns
            Write-Host "Reverting patch..." -ForegroundColor Yellow
            for ($i = 0; $i -lt $originalPattern.Length; $i++) {
                $fileBytes[$patchedOffset + $i] = $originalPattern[$i]
            }
            
            [System.IO.File]::WriteAllBytes($FilePath, $fileBytes)
            Write-Host "Patch reverted successfully!" -ForegroundColor Green
            Write-Host "  From: $(($targetPattern | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor Red
            Write-Host "  To:   $(($originalPattern | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor Green
        } else {
            Write-Host "No changes made." -ForegroundColor Cyan
        }
    } else {
        $offset = Find-BytePattern -FileBytes $fileBytes -Pattern $originalPattern
        
        if ($offset -eq -1) {
            Write-Host ""
            Write-Host "Original pattern not found in $exeName" -ForegroundColor Red
            Write-Host ""
            Write-Host "The file may:" -ForegroundColor Yellow
            Write-Host "1. Already be patched" -ForegroundColor White
            Write-Host "2. Be a different version" -ForegroundColor White
            Write-Host "3. Not contain the expected pattern" -ForegroundColor White
            Write-Host ""
            Write-Host "Searching for similar patterns..." -ForegroundColor Cyan
            
            # Look for partial matches
            $partialPattern = @(0x0F, 0x85, 0x8A, 0x00, 0x00, 0x00)  # Just the jump instruction
            $partialOffset = Find-BytePattern -FileBytes $fileBytes -Pattern $partialPattern
            
            if ($partialOffset -ne -1) {
                Write-Host "Found similar pattern at offset: 0x$($partialOffset.ToString('X8'))" -ForegroundColor Yellow
                $contextStart = [Math]::Max(0, $partialOffset - 8)
                $contextEnd = [Math]::Min($fileBytes.Length - 1, $partialOffset + 16)
                $contextBytes = $fileBytes[$contextStart..$contextEnd]
                Write-Host "Context: $(($contextBytes | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor White
            }
        } else {
            Write-Host ""
            Write-Host "Original pattern found at offset: 0x$($offset.ToString('X8'))" -ForegroundColor Yellow
            
            # Display the bytes to be changed
            Write-Host "Current bytes at offset:" -ForegroundColor Cyan
            $currentBytes = $fileBytes[$offset..($offset + $originalPattern.Length - 1)]
            Write-Host "  $(($currentBytes | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor White
            
            # Confirm before patching
            Write-Host ""
            Write-Host "This will change:" -ForegroundColor Yellow
            Write-Host "  0F 85 (JNZ - conditional jump) -> 48 E9 (JMP - unconditional jump)" -ForegroundColor White
            Write-Host ""
            $response = Read-Host "Proceed with patch? (Y/n)"
            if ($response -eq 'n' -or $response -eq 'N') {
                Write-Host "Patch cancelled." -ForegroundColor Yellow
            } else {
                # Patch the bytes
                for ($i = 0; $i -lt $targetPattern.Length; $i++) {
                    $fileBytes[$offset + $i] = $targetPattern[$i]
                }
                
                # Write the patched file
                [System.IO.File]::WriteAllBytes($FilePath, $fileBytes)
                
                Write-Host ""
                Write-Host "Successfully patched bytes:" -ForegroundColor Green
                Write-Host "  From: $(($originalPattern | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor Red
                Write-Host "  To:   $(($targetPattern | ForEach-Object { $_.ToString('X2') }) -join ' ')" -ForegroundColor Green
                
                # Verify the patch
                $verifyBytes = [System.IO.File]::ReadAllBytes($FilePath)
                $verifyOffset = Find-BytePattern -FileBytes $verifyBytes -Pattern $targetPattern
                
                if ($verifyOffset -eq $offset) {
                    Write-Host "Patch verification successful!" -ForegroundColor Green
                } else {
                    Write-Error "Patch verification failed!"
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "=== Process Complete ===" -ForegroundColor Green
    Write-Host "Final directory with all files: $finalDir" -ForegroundColor Cyan
    Write-Host "Patched executable: $(Split-Path $FilePath -Leaf)" -ForegroundColor Green
    
} catch {
    Write-Error "An error occurred: $($_.Exception.Message)"
} finally {
    if ($extractDir -and (Test-Path $extractDir)) {
        Write-Host ""
        $cleanupResponse = Read-Host "Delete temporary extraction directory? (Y/n)"
        if ($cleanupResponse -ne 'n' -and $cleanupResponse -ne 'N') {
            Remove-Item $extractDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✓ Temporary extraction directory cleaned up" -ForegroundColor Green
        } else {
            Write-Host "Temporary extraction directory preserved: $extractDir" -ForegroundColor Cyan
        }
    }
}