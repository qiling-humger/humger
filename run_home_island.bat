@echo off
chcp 65001 >nul
set "GODOT=F:\humger\tools\godot\Godot_v4.7.2-stable_win64.exe"
set "PROJECT=F:\humger\HamburgerStory"
if not exist "%GODOT%" set "GODOT=F:\humger\tools\godot\Godot_v4.7.2-stable_win64_console.exe"
start "" "%GODOT%" --path "%PROJECT%" "res://tutorial/TutorialLevel.tscn"

