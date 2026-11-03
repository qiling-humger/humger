$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Godot = Join-Path $ProjectRoot "..\tools\godot\Godot_v4.7.2-stable_win64.exe"
if (-not (Test-Path -LiteralPath $Godot)) {
    Write-Host "Godot not found: $Godot" -ForegroundColor Red
    Write-Host "Open project.godot with Godot 4.7.2 instead."
    exit 1
}
# Keep Godot's cache inside the project; the default AppData cache
# directory is not writable on this machine.
$env:APPDATA = Join-Path $ProjectRoot ".userdata\roaming"
$env:LOCALAPPDATA = Join-Path $ProjectRoot ".userdata\local"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
& $Godot --path $ProjectRoot
exit $LASTEXITCODE
