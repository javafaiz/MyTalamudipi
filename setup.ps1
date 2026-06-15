# setup.ps1 — MY Talamudipi Full Setup Script
# Run this script from the MyTalamudipi root folder:
#   .\setup.ps1
# Prerequisites: Internet connection, Windows 10/11

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "   MY Talamudipi — Setup Script" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Install Flutter ──────────────────────────────────────────────────
function Install-Flutter {
    Write-Host "[1/6] Checking Flutter..." -ForegroundColor Yellow

    if (Get-Command flutter -ErrorAction SilentlyContinue) {
        $ver = (flutter --version 2>&1 | Select-String 'Flutter').ToString()
        Write-Host "      Flutter already installed: $ver" -ForegroundColor Green
        return
    }

    Write-Host "      Flutter not found. Downloading Flutter SDK..." -ForegroundColor Yellow

    $flutterZip = "$env:TEMP\flutter_windows.zip"
    $flutterDir = "C:\flutter"

    if (-not (Test-Path $flutterDir)) {
        Write-Host "      Downloading from storage.googleapis.com..." -ForegroundColor Gray
        Invoke-WebRequest `
            -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.24.5-stable.zip" `
            -OutFile $flutterZip `
            -UseBasicParsing

        Write-Host "      Extracting to C:\flutter ..." -ForegroundColor Gray
        Expand-Archive -Path $flutterZip -DestinationPath "C:\" -Force
        Remove-Item $flutterZip -Force
    }

    # Add to PATH for this session
    $env:PATH = "C:\flutter\bin;$env:PATH"

    # Add permanently to user PATH
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*C:\flutter\bin*") {
        [Environment]::SetEnvironmentVariable("PATH", "C:\flutter\bin;$currentPath", "User")
        Write-Host "      Added C:\flutter\bin to user PATH." -ForegroundColor Green
    }

    Write-Host "      Flutter installed successfully." -ForegroundColor Green
}

# ── Step 2: Install Android SDK via command-line tools ───────────────────────
function Check-AndroidSdk {
    Write-Host "[2/6] Checking Android SDK..." -ForegroundColor Yellow

    $androidHome = $env:ANDROID_HOME
    if (-not $androidHome) { $androidHome = $env:ANDROID_SDK_ROOT }

    if ($androidHome -and (Test-Path "$androidHome\platform-tools")) {
        Write-Host "      Android SDK found at: $androidHome" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "  ⚠  Android SDK not found." -ForegroundColor Red
        Write-Host "     Please install Android Studio from:" -ForegroundColor Yellow
        Write-Host "     https://developer.android.com/studio" -ForegroundColor Cyan
        Write-Host "     Then re-run this script." -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
}

# ── Step 3: Accept Android licenses ─────────────────────────────────────────
function Accept-Licenses {
    Write-Host "[3/6] Accepting Android licenses..." -ForegroundColor Yellow
    $yes = "y`ny`ny`ny`ny`ny`n"
    $yes | flutter doctor --android-licenses 2>&1 | Out-Null
    Write-Host "      Licenses accepted." -ForegroundColor Green
}

# ── Step 4: Create Flutter project skeleton ──────────────────────────────────
function Create-FlutterProject {
    Write-Host "[4/6] Creating Flutter project skeleton..." -ForegroundColor Yellow

    $appDir = Join-Path $ROOT "app"

    if (-not (Test-Path "$appDir\android")) {
        # flutter create needs a clean directory; our lib/ files are already there
        # so we create in a temp location and merge
        $tmpDir = Join-Path $env:TEMP "talamudipi_tmp"
        if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }

        flutter create `
            --org com.mytalamudipi `
            --project-name my_talamudipi `
            --platforms android `
            $tmpDir

        # Copy android/, generated files (but NOT lib/ — we have our own)
        Copy-Item "$tmpDir\android"   "$appDir\android"   -Recurse -Force
        Copy-Item "$tmpDir\.gitignore" "$appDir\.gitignore" -Force -ErrorAction SilentlyContinue
        Copy-Item "$tmpDir\analysis_options.yaml" "$appDir\analysis_options.yaml" -Force -ErrorAction SilentlyContinue

        Remove-Item $tmpDir -Recurse -Force
        Write-Host "      Android project scaffold created." -ForegroundColor Green
    } else {
        Write-Host "      Android folder already exists, skipping create." -ForegroundColor Green
    }
}

# ── Step 5: Download Noto Sans Telugu font ────────────────────────────────────
function Download-Fonts {
    Write-Host "[5/6] Downloading Noto Sans Telugu font..." -ForegroundColor Yellow

    $fontDir = Join-Path $ROOT "app\assets\fonts"
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null

    $regularUrl = "https://github.com/google/fonts/raw/main/ofl/notosanstelugu/NotoSansTelugu%5Bwdth%2Cwght%5D.ttf"
    $regularPath = Join-Path $fontDir "NotoSansTelugu-Regular.ttf"
    $boldPath    = Join-Path $fontDir "NotoSansTelugu-Bold.ttf"

    if (-not (Test-Path $regularPath)) {
        try {
            Invoke-WebRequest -Uri $regularUrl -OutFile $regularPath -UseBasicParsing
            Copy-Item $regularPath $boldPath -Force
            Write-Host "      Font downloaded." -ForegroundColor Green
        } catch {
            Write-Host "      ⚠  Could not download font automatically." -ForegroundColor Red
            Write-Host "         Download NotoSansTelugu-Regular.ttf manually from:" -ForegroundColor Yellow
            Write-Host "         https://fonts.google.com/noto/specimen/Noto+Sans+Telugu" -ForegroundColor Cyan
            Write-Host "         and place both Regular and Bold .ttf files in:" -ForegroundColor Yellow
            Write-Host "         $fontDir" -ForegroundColor Cyan
        }
    } else {
        Write-Host "      Font already present." -ForegroundColor Green
    }
}

# ── Step 6: Extract PDF → voters.db ─────────────────────────────────────────
function Extract-VoterData {
    Write-Host "[6/6] Extracting voter data from PDF..." -ForegroundColor Yellow

    $extractScript = Join-Path $ROOT "scripts\extract_voters.py"
    $assetsDir     = Join-Path $ROOT "app\assets"
    New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null

    $dbPath = Join-Path $assetsDir "voters.db"

    if (Test-Path $dbPath) {
        Write-Host "      voters.db already exists — skipping extraction." -ForegroundColor Green
        Write-Host "      Delete $dbPath to re-extract." -ForegroundColor Gray
    } else {
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Write-Host "      Running extraction script..." -ForegroundColor Gray
            python $extractScript --db $dbPath
        } elseif (Get-Command python3 -ErrorAction SilentlyContinue) {
            python3 $extractScript --db $dbPath
        } else {
            Write-Host "      ⚠  Python not found. Run manually:" -ForegroundColor Red
            Write-Host "         python scripts\extract_voters.py --db app\assets\voters.db" -ForegroundColor Yellow
        }
    }
}

# ── Step 7: flutter pub get + build APK ──────────────────────────────────────
function Build-Apk {
    Write-Host ""
    Write-Host "[7/7] Building APK..." -ForegroundColor Yellow

    $appDir = Join-Path $ROOT "app"
    Set-Location $appDir

    Write-Host "      Running flutter pub get..." -ForegroundColor Gray
    flutter pub get

    Write-Host "      Building release APK (this may take 3-5 minutes)..." -ForegroundColor Gray
    flutter build apk --release

    $apkPath = Join-Path $appDir "build\app\outputs\flutter-apk\app-release.apk"
    if (Test-Path $apkPath) {
        $dest = Join-Path $ROOT "MyTalamudipi.apk"
        Copy-Item $apkPath $dest -Force
        Write-Host ""
        Write-Host "================================================" -ForegroundColor Green
        Write-Host "   SUCCESS! APK ready:" -ForegroundColor Green
        Write-Host "   $dest" -ForegroundColor Cyan
        Write-Host "================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "   Transfer MyTalamudipi.apk to your Android phone" -ForegroundColor White
        Write-Host "   and install it (enable 'Install unknown apps')." -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "   Build may have failed. Check output above." -ForegroundColor Red
    }

    Set-Location $ROOT
}

# ── Run all steps ─────────────────────────────────────────────────────────────
Install-Flutter
Check-AndroidSdk
Accept-Licenses
Create-FlutterProject
Download-Fonts
Extract-VoterData
Build-Apk
