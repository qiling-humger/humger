@echo off
cd /d "%~dp0"
set GODOT=..\tools\godot\Godot_v4.7.2-stable_win64_console.exe
if not exist "%GODOT%" (
  echo 找不到 Godot: %GODOT%
  pause
  exit /b 1
)
set APPDATA=%CD%\.userdata\roaming
set LOCALAPPDATA=%CD%\.userdata\local
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
echo === 窗口模式完整验收（含鼠标） ===
"%GODOT%" --path . res://tests/TestRunner.tscn
echo.
pause
