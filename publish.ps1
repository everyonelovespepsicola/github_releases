# ==================================================
# GITHUB RELEASE MANAGER - MASTER BUILD ORCHESTRATOR
# ==================================================
$ErrorActionPreference = "Stop"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  GITHUB RELEASE MANAGER - BUILD ORCHESTRATOR     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$FLUTTER_SDK_DIR = "C:\src\flutter"
$BIN_OUT = Join-Path $SCRIPT_DIR "bin"

# 1. Resolve Flutter SDK Environment
Write-Host "[1/5] Resolving Flutter SDK Environment..." -ForegroundColor Yellow
if (Test-Path "$FLUTTER_SDK_DIR\bin\flutter.bat") {
    $env:PATH = "$FLUTTER_SDK_DIR\bin;$env:PATH"
    Write-Host "    [+] Found Flutter SDK at $FLUTTER_SDK_DIR" -ForegroundColor Green
} elseif (Get-Command "flutter" -ErrorAction SilentlyContinue) {
    Write-Host "    [+] Using Flutter from system PATH" -ForegroundColor Green
} else {
    Write-Host "    [-] Flutter SDK not found at $FLUTTER_SDK_DIR" -ForegroundColor Red
    exit 1
}

# 2. Check and Install Global Prerequisites via Winget (GitHub CLI)
Write-Host "[2/5] Checking Global Prerequisites via Winget..." -ForegroundColor Yellow
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Host "    [!] GitHub CLI (gh) not detected. Attempting automated winget installation..." -ForegroundColor Yellow
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        try {
            winget install --id GitHub.cli -e --silent --accept-source-agreements --accept-package-agreements
            Write-Host "    [+] GitHub CLI installed successfully via winget!" -ForegroundColor Green
        } catch {
            Write-Host "    [-] Winget failed to install GitHub CLI. Continuing..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "    [-] Winget not found. Please install GitHub CLI manually from https://cli.github.com" -ForegroundColor Yellow
    }
} else {
    Write-Host "    [+] GitHub CLI (gh) is available." -ForegroundColor Green
}

Set-Location $SCRIPT_DIR

# 3. Initialize Flutter Windows project structure if missing
Write-Host "[3/5] Checking Flutter Project Structure..." -ForegroundColor Yellow
if (-not (Test-Path "$SCRIPT_DIR\pubspec.yaml")) {
    Write-Host "    [!] Project files missing. Initializing Flutter Windows application..." -ForegroundColor Yellow
    C:\src\flutter\bin\flutter.bat create --platforms=windows --org com.githubreleases.app .
}

# 3.5 Terminate Any Running Instances to Prevent File Lock Failures
Write-Host "    [!] Scanning for running github_releases.exe processes..." -ForegroundColor Yellow
$runningProcesses = Get-Process -Name "github_releases" -ErrorAction SilentlyContinue
if ($runningProcesses) {
    Write-Host "    [!] Found $($runningProcesses.Count) running instance(s). Terminating..." -ForegroundColor Yellow
    Stop-Process -Name "github_releases" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
}

# 4. Resolve Dependencies
Write-Host "[4/5] Resolving Package Dependencies..." -ForegroundColor Yellow
C:\src\flutter\bin\flutter.bat pub get

# Add C++ coroutine flag to CMakeLists.txt if needed
$CMAKE_FILE = "$SCRIPT_DIR\windows\CMakeLists.txt"
if (Test-Path $CMAKE_FILE) {
    $cmakeContent = Get-Content $CMAKE_FILE -Raw
    if (-not $cmakeContent.Contains("_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS")) {
        $cmakeContent = $cmakeContent.Replace("add_definitions(-DUNICODE -D_UNICODE)", "add_definitions(-DUNICODE -D_UNICODE -D_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS)")
        Set-Content -Path $CMAKE_FILE -Value $cmakeContent -Force
    }
}

# 5. Compile Windows Desktop EXE & Create Release ZIP
Write-Host "[5/5] Compiling Windows Native Desktop Application..." -ForegroundColor Yellow
C:\src\flutter\bin\flutter.bat build windows --target=lib/main.dart

if (-not (Test-Path $BIN_OUT)) { New-Item -ItemType Directory -Path $BIN_OUT -Force | Out-Null }

$BUILT_EXE_DIR = "$SCRIPT_DIR\build\windows\x64\runner\Release"
$TARGET_EXE_DIR = "$BIN_OUT\github-releases-windows-release"

if (Test-Path $BUILT_EXE_DIR) {
    Stop-Process -Name "github_releases" -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    if (-not (Test-Path $TARGET_EXE_DIR)) { New-Item -ItemType Directory -Path $TARGET_EXE_DIR -Force | Out-Null }
    Copy-Item -Path "$BUILT_EXE_DIR\*" -Destination $TARGET_EXE_DIR -Recurse -Force
    
    # Create ZIP archive
    $ZIP_PATH = "$BIN_OUT\github-releases-windows-v1.0.0.zip"
    if (Test-Path $ZIP_PATH) { Remove-Item $ZIP_PATH -Force }
    Compress-Archive -Path "$TARGET_EXE_DIR\*" -DestinationPath $ZIP_PATH -Force
    Write-Host "    [+] Created Release ZIP Package: $ZIP_PATH" -ForegroundColor Green
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "  [+] GitHub Release Manager Build Complete!" -ForegroundColor Green
Write-Host "      Windows EXE: $TARGET_EXE_DIR\github_releases.exe" -ForegroundColor Yellow
Write-Host "      Release ZIP: $BIN_OUT\github-releases-windows-v1.0.0.zip" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Green
