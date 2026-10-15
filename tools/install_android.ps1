param([string]$Serial = 'emulator-5554', [string]$AndroidSdk = "$env:LOCALAPPDATA/Android/Sdk")
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$adb = Join-Path $AndroidSdk 'platform-tools/adb.exe'
$apk = Join-Path $projectRoot 'artifacts/ashen-oath-debug.apk'
if (-not (Test-Path -LiteralPath $apk)) { throw 'Build first: tools/build.ps1' }
& $adb -s $Serial install --no-incremental -r $apk
if ($LASTEXITCODE -ne 0) { throw 'ADB installation failed' }
& $adb -s $Serial shell am start -W -a 'android.intent.action.MAIN' -c 'android.intent.category.LAUNCHER' -p 'org.ashenoath.app'
if ($LASTEXITCODE -ne 0) { throw 'ADB launch failed' }


