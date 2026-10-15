param([string]$KeyDirectory = "$env:USERPROFILE/.codex/signing/ashen-oath")
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$godot = Join-Path $root '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
$sdk = "$env:LOCALAPPDATA/Android/Sdk/build-tools/36.0.0"
$keytool = 'C:/Program Files/Java/jdk-17/bin/keytool.exe'
$store = Join-Path $KeyDirectory 'ashen-oath-release.jks'
$credentialPath = Join-Path $KeyDirectory 'signing-credential.xml'
$alias = 'ashen-oath-release'
New-Item -ItemType Directory -Force -Path $KeyDirectory | Out-Null
if ((Test-Path -LiteralPath $store) -ne (Test-Path -LiteralPath $credentialPath)) { throw 'Keystore and credential must both exist; restore the missing file before continuing.' }
if (-not (Test-Path -LiteralPath $store)) {
 $bytes = [byte[]]::new(36)
 [Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
 $secure = ConvertTo-SecureString ([Convert]::ToBase64String($bytes)) -AsPlainText -Force
 [PSCredential]::new($alias,$secure) | Export-Clixml -LiteralPath $credentialPath
 $credential = Import-Clixml -LiteralPath $credentialPath
 $env:ASHEN_RELEASE_PASSWORD = $credential.GetNetworkCredential().Password
 try {
  & $keytool -genkeypair -keystore $store -storetype JKS -alias $alias -keyalg RSA -keysize 3072 -validity 10000 -dname 'CN=Embertrail Studio, OU=Ashen Oath' -storepass:env ASHEN_RELEASE_PASSWORD -keypass:env ASHEN_RELEASE_PASSWORD
  if ($LASTEXITCODE -ne 0) { throw 'Release keystore creation failed' }
 } finally { Remove-Item Env:ASHEN_RELEASE_PASSWORD }
}
$credential = Import-Clixml -LiteralPath $credentialPath
$env:ASHEN_RELEASE_PASSWORD = $credential.GetNetworkCredential().Password
try {
 & $godot --headless --path $root --editor --quit
 if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
 $unsigned = Join-Path $root '.tools/ashen-oath-0.7.2-release-unsigned.apk'
 $aligned = Join-Path $root '.tools/ashen-oath-release-aligned.apk'
 $final = Join-Path $root 'artifacts/rustore/ashen-oath-0.7.2-release.apk'
 & $godot --headless --path $root --export-release 'RuStore Release' $unsigned
 if ($LASTEXITCODE -ne 0) { throw 'Release export failed' }
 & "$sdk/zipalign.exe" -f -P 16 4 $unsigned $aligned
 if ($LASTEXITCODE -ne 0) { throw 'ZIP alignment failed' }
 & "$sdk/apksigner.bat" sign --ks $store --ks-key-alias $alias --ks-pass env:ASHEN_RELEASE_PASSWORD --key-pass env:ASHEN_RELEASE_PASSWORD --out $final $aligned
 if ($LASTEXITCODE -ne 0) { throw 'Release signing failed' }
 & "$sdk/apksigner.bat" verify --verbose --print-certs $final | Set-Content -Encoding utf8 (Join-Path $root 'artifacts/rustore/signature-report.txt')
 if ($LASTEXITCODE -ne 0) { throw 'Release signature verification failed' }
 & "$sdk/zipalign.exe" -c -P 16 -v 4 $final | Set-Content -Encoding utf8 (Join-Path $root 'artifacts/rustore/alignment-report.txt')
 if ($LASTEXITCODE -ne 0) { throw 'Signed APK alignment failed' }
 Get-FileHash -LiteralPath $final -Algorithm SHA256
} finally { Remove-Item Env:ASHEN_RELEASE_PASSWORD }
