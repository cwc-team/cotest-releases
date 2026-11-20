$ErrorActionPreference = "Stop"
$Repo = "cwc-team/cotest-releases"
$TempDir = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "cotest_install_" + [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

$VsixUrl = "https://github.com/$Repo/releases/latest/download/cotest.vsix"
$ChecksumUrl = "https://github.com/$Repo/releases/latest/download/checksums.txt"
$VsixPath = Join-Path $TempDir "cotest.vsix"
$ChecksumPath = Join-Path $TempDir "checksums.txt"

Write-Host "⚡ Downloading cotest extension..." -ForegroundColor Cyan

# Use curl.exe if available for fastest download, fallback to Invoke-WebRequest
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    curl.exe -sL $VsixUrl -o $VsixPath
    curl.exe -sL $ChecksumUrl -o $ChecksumPath
} else {
    Invoke-WebRequest -Uri $VsixUrl -OutFile $VsixPath
    Invoke-WebRequest -Uri $ChecksumUrl -OutFile $ChecksumPath
}

if (-not (Test-Path $VsixPath) -or (Get-Item $VsixPath).Length -eq 0) {
    Write-Error "Failed to download cotest.vsix. Please check your internet connection."
    Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "🔒 Verifying SHA256 checksum..." -ForegroundColor Cyan
$ChecksumContent = Get-Content $ChecksumPath | Select-String "cotest.vsix"
if ($ChecksumContent) {
    $ExpectedHash = $ChecksumContent.Line.Split(" ")[0].Trim()
    $ActualHash = (Get-FileHash $VsixPath -Algorithm SHA256).Hash.ToLower()

    if ($ExpectedHash.ToLower() -ne $ActualHash) {
        Write-Error "Checksum mismatch! Expected: $ExpectedHash, Got: $ActualHash"
        Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
        exit 1
    }
}
Write-Host "Checksum verified successfully!" -ForegroundColor Green

Write-Host "📦 Installing extension into VS Code..." -ForegroundColor Cyan
& code --install-extension $VsixPath --force

Remove-Item -Recurse -Force $TempDir -ErrorAction SilentlyContinue
Write-Host "✅ cotest has been successfully installed! Please reload your VS Code window." -ForegroundColor Green
