param([ValidateSet('Android','Windows Desktop')][string]$Platform = 'Android')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$workspaceDrive = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($projectRoot))
if ($workspaceDrive.AvailableFreeSpace -lt 1GB) { throw "Build needs at least 1 GB free for temporary export files" }
$godot = Join-Path $projectRoot '.tools/godot/Godot_v4.7.2-stable_win64_console.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw 'Run tools/setup.ps1 -Download first.' }
New-Item -ItemType Directory -Force -Path (Join-Path $projectRoot 'artifacts') | Out-Null
& $godot --headless --path $projectRoot --editor --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed' }
# Keep regenerated 3D assets in the Android texture budget as well.
$mobileImportsChanged = $false
foreach ($assetFolder in @('assets/models/verdant_mobile', 'assets/models/foliage', 'assets/models/private_maiden', 'assets/materials')) {
    $assetPath = Join-Path $projectRoot $assetFolder
    if (-not (Test-Path -LiteralPath $assetPath)) { continue }
    foreach ($importFile in (Get-ChildItem -LiteralPath $assetPath -Recurse -File -Filter '*.import')) {
        if ($importFile.Name -notmatch '\.(png|jpg)\.import$') { continue }
        $originalImport = [IO.File]::ReadAllText($importFile.FullName)
        $mobileImport = $originalImport.Replace('compress/mode=0', 'compress/mode=2').Replace('mipmaps/generate=false', 'mipmaps/generate=true')
        if ($mobileImport -ne $originalImport) {
            [IO.File]::WriteAllText($importFile.FullName, $mobileImport, [Text.UTF8Encoding]::new($false))
            $mobileImportsChanged = $true
        }
    }
}
if ($mobileImportsChanged) {
    & $godot --headless --path $projectRoot --editor --quit
    if ($LASTEXITCODE -ne 0) { throw 'Mobile texture import failed' }
}

$output = if ($Platform -eq 'Android') { 'artifacts/ashen-oath-debug.apk' } else { 'artifacts/AshenOath.exe' }
& $godot --headless --path $projectRoot --export-debug $Platform (Join-Path $projectRoot $output)
if ($LASTEXITCODE -ne 0) { throw "Export failed: $Platform" }
if ($Platform -eq 'Android') {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $apkArchive = [IO.Compression.ZipFile]::OpenRead((Join-Path $projectRoot $output))
    try {
        $emptyResources = @($apkArchive.Entries | Where-Object { $_.FullName.StartsWith('assets/.godot/imported/') -and $_.Length -eq 0 })
        if ($emptyResources.Count -gt 0) { throw "APK contains $($emptyResources.Count) empty imported resources; check free disk space" }
    } finally { $apkArchive.Dispose() }
}
Get-FileHash -LiteralPath (Join-Path $projectRoot $output) -Algorithm SHA256


