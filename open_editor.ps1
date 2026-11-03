$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Godot = Join-Path $ProjectRoot "..\tools\godot\Godot_v4.7.2-stable_win64.exe"
if (-not (Test-Path -LiteralPath $Godot)) {
    Write-Host "Godot not found: $Godot" -ForegroundColor Red
    exit 1
}
$env:APPDATA = Join-Path $ProjectRoot ".userdata\roaming"
$env:LOCALAPPDATA = Join-Path $ProjectRoot ".userdata\local"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
& $Godot --editor --path $ProjectRoot
exit $LASTEXITCODE
