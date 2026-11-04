$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$GodotExe = "F:\humger\tools\godot\Godot_v4.7.2-stable_win64.exe"
if (-not (Test-Path -LiteralPath $GodotExe)) {
    $GodotExe = Join-Path (Split-Path -Parent $ProjectRoot) "tools\godot\Godot_v4.7.2-stable_win64.exe"
}
$env:APPDATA = Join-Path $ProjectRoot ".userdata\roaming"
$env:LOCALAPPDATA = Join-Path $ProjectRoot ".userdata\local"
New-Item -ItemType Directory -Force -Path $env:APPDATA, $env:LOCALAPPDATA | Out-Null
& $GodotExe --path $ProjectRoot "res://map_prototype/MapPrototype.tscn"
