param(
    [string]$BaseDir = "downloaded-youtube"
)

if (-not (Test-Path $BaseDir -PathType Container)) {
    Write-Host "Error: directory not found: $BaseDir"
    exit 1
}

$partDirs = Get-ChildItem -Path $BaseDir -Directory -Filter "*-parts"

if ($partDirs.Count -eq 0) {
    Write-Host "No YouTube part folders found in: $BaseDir"
    Write-Host "Expected folders like:"
    Write-Host "  downloaded-youtube\video-1-mp4-parts\"
    exit 0
}

foreach ($partDir in $partDirs) {
    $parts = Get-ChildItem -Path $partDir.FullName -File -Filter "*.part-*" | Sort-Object Name

    if ($parts.Count -eq 0) {
        Write-Host "Skipping empty parts folder: $($partDir.FullName)"
        continue
    }

    $firstPartName = $parts[0].Name

    # Example:
    # video-1.mp4.part-000 -> video-1.mp4
    $outputName = $firstPartName -replace "\.part-\d+$", ""

    if ($outputName -eq $firstPartName) {
        $outputName = $firstPartName -replace "\.part-.*$", ""
    }

    $outputFile = Join-Path $BaseDir $outputName

    Write-Host "Rebuilding YouTube video:"
    Write-Host "  From: $($partDir.FullName)"
    Write-Host "  To:   $outputFile"

    if (Test-Path $outputFile) {
        Write-Host "  Existing output found. Removing: $outputFile"
        Remove-Item $outputFile -Force
    }

    $outStream = [System.IO.File]::OpenWrite($outputFile)

    try {
        foreach ($part in $parts) {
            Write-Host "  Adding: $($part.Name)"

            $inStream = [System.IO.File]::OpenRead($part.FullName)

            try {
                $inStream.CopyTo($outStream)
            }
            finally {
                $inStream.Close()
            }
        }
    }
    finally {
        $outStream.Close()
    }

    $finalSize = (Get-Item $outputFile).Length

    Write-Host "Done: $outputFile"
    Write-Host "Size: $finalSize bytes"
    Write-Host ""
}

Write-Host "All YouTube part folders processed."
