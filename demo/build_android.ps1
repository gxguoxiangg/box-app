<#
.SYNOPSIS
    Build an installable Android release APK.

.DESCRIPTION
    The script is stored in the demo folder. It locates the Flutter project root
    from its own path and copies the build output back to the demo folder.

.EXAMPLE
    .\build_android.ps1

.EXAMPLE
    .\build_android.ps1 -SkipPubGet
#>

[CmdletBinding()]
param(
    # Use this switch when dependencies are already available.
    [switch]$SkipPubGet
)

$ErrorActionPreference = 'Stop'

$demoDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDirectory = Split-Path -Parent $demoDirectory
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
$sourceApk = Join-Path $projectDirectory 'build\app\outputs\flutter-apk\app-release.apk'
$outputApk = Join-Path $demoDirectory 'demo2-android-release.apk'

if ($null -eq $flutterCommand) {
    throw 'Flutter command was not found. Install Flutter SDK and add it to PATH.'
}

if (-not (Test-Path (Join-Path $projectDirectory 'pubspec.yaml'))) {
    throw "pubspec.yaml was not found. Project root detection failed: $projectDirectory"
}

New-Item -ItemType Directory -Path $demoDirectory -Force | Out-Null
Set-Location $projectDirectory

if (-not $SkipPubGet) {
    Write-Host 'Fetching Flutter dependencies...' -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter dependency resolution failed. Exit code: $LASTEXITCODE"
    }
}

Write-Host 'Building Android release APK...' -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) {
    throw "Android APK build failed. Exit code: $LASTEXITCODE"
}

if (-not (Test-Path $sourceApk)) {
    throw "Build completed, but the APK was not found: $sourceApk"
}

Copy-Item -LiteralPath $sourceApk -Destination $outputApk -Force
$apkSize = [math]::Round((Get-Item -LiteralPath $outputApk).Length / 1MB, 2)

Write-Host "Build complete: $outputApk" -ForegroundColor Green
Write-Host "File size: $apkSize MB" -ForegroundColor Green
