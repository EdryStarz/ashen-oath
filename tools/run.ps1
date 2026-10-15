$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $projectRoot '.tools/godot/Godot_v4.7.2-stable_win64.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Run tools/setup.ps1 -Download first.' }
& $godot --path $projectRoot
