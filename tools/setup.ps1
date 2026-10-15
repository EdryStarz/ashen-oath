param(
    [string]$AndroidSdk = "$env:LOCALAPPDATA/Android/Sdk",
    [string]$JavaSdk = 'C:/Program Files/Java/jdk-17',
    [switch]$Download,
    [switch]$InstallModder
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$engineRoot = Join-Path $projectRoot '.tools/godot'
New-Item -ItemType Directory -Force -Path $engineRoot | Out-Null
if ($Download) {
    python (Join-Path $PSScriptRoot 'download_godot.py') all
    if ($LASTEXITCODE -ne 0) { throw 'Godot download failed' }
}
New-Item -ItemType File -Force -Path (Join-Path $engineRoot '_sc_') | Out-Null
$settingsRoot = Join-Path $engineRoot 'editor_data'
New-Item -ItemType Directory -Force -Path $settingsRoot | Out-Null
$settingsPath = Join-Path $settingsRoot 'editor_settings-4.7.tres'
$androidPath = $AndroidSdk.Replace('\', '/')
$javaPath = $JavaSdk.Replace('\', '/')
$settingsText = @"
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$androidPath"
export/android/java_sdk_path = "$javaPath"
export/android/shutdown_adb_on_exit = false
"@
Set-Content -LiteralPath $settingsPath -Value $settingsText -Encoding utf8
if ($InstallModder) {
    $venvPath = Join-Path $projectRoot '.tools/um-env'
    if (-not (Test-Path (Join-Path $venvPath 'Scripts/python.exe'))) {
        python -m venv $venvPath
        if ($LASTEXITCODE -ne 0) { throw 'Could not create local Python environment' }
    }
    & (Join-Path $venvPath 'Scripts/python.exe') -m pip install 'universal-modder @ git+https://github.com/rehan-remade/universal-modder'
    if ($LASTEXITCODE -ne 0) { throw 'Universal-modder install failed' }
}
Write-Output 'Portable Godot settings configured; Android SDK and Java remain unchanged.'

