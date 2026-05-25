# Production web build: bundle CanvasKit locally (no gstatic CDN).
Set-Location $PSScriptRoot\..
flutter build web --release --no-web-resources-cdn @args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "Output: build\web (deploy this folder)"
