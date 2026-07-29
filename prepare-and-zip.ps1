# Prepare m4cnik-app for GitHub upload (no git required)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

Write-Host "==> Generating app icon..."
python make-icon.py
if ($LASTEXITCODE -ne 0) {
    py make-icon.py
}

$iconJson = @'
{
  "images" : [
    {
      "filename" : "icon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
'@
Set-Content -Path "M4cNikApp\Assets.xcassets\AppIcon.appiconset\Contents.json" -Value $iconJson -Encoding UTF8

$zipPath = Join-Path (Split-Path $root -Parent) "m4cnik-app-github.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

$items = @(
    ".github",
    "M4cNikApp",
    "M4cNikApp.xcodeproj",
    "build-ipa.sh",
    "make-icon.py"
)
Compress-Archive -Path $items -DestinationPath $zipPath -Force

Write-Host ""
Write-Host "Ready: $zipPath"
Write-Host ""
Write-Host "Next steps:"
Write-Host "1. Create empty repo on GitHub (e.g. m4cnik-app)"
Write-Host "2. Upload zip contents OR use GitHub web 'Upload files'"
Write-Host "3. Actions -> Build M4cNik IPA -> Run workflow"
Write-Host "4. Download artifact M4cNikApp-ipa"
