# make-md5sums-robust.ps1

# This script run successfully on May 20, 2026. It runs md5 checksum on fastq files in Windows PowerShell.

# Run in PowerShell
# powershell -ExecutionPolicy Bypass -File .\make-md5sums-robust.ps1

$Root    = "D:\Shares\data\NGS\scRNA-seq"
$OutMd5  = Join-Path $Root "md5sums.md5"
$OutErr  = Join-Path $Root "md5_errors.tsv"

# Reset output files
"" | Out-File -FilePath $OutMd5 -Encoding ascii
"Path`tError" | Out-File -FilePath $OutErr -Encoding utf8

# Enumerate files
$files = Get-ChildItem -Path $Root -Recurse -File -Filter "*.fastq.gz" -ErrorAction Stop

foreach ($f in $files) {
    try {
        $hash = (Get-FileHash -Path $f.FullName -Algorithm MD5 -ErrorAction Stop).Hash.ToLower()
        "$hash  $($f.FullName)" | Out-File -FilePath $OutMd5 -Append -Encoding ascii
    }
    catch {
        $msg = $_.Exception.Message -replace "`r|`n"," "
        "$($f.FullName)`t$msg" | Out-File -FilePath $OutErr -Append -Encoding utf8
        Write-Warning "FAILED: $($f.FullName) :: $msg"
        continue
    }
}

Write-Host "Done."
Write-Host "MD5 list:   $OutMd5"
Write-Host "Error log:  $OutErr"
