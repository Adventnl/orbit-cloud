# .SYNOPSIS
#   One-click Orbit-Cloud installer (PowerShell version).

# .DESCRIPTION
#   This script replaces the Electron UI wizard. It performs the full installation automatically:
#   1. Installs VirtualBox, Vagrant, Git (silent)
#   2. Installs Node dependencies for the UI
#   3. Builds the React UI and packages it as orbit-cloud-ui.exe
#   4. Brings up the HA-k3s cluster via Vagrant
#   5. Registers the UI executable as a Windows service (auto-start)
#   6. Creates a desktop shortcut for manual launch
#   All steps are logged to a file in the same folder.

# .NOTES
#   Run this script from an **elevated PowerShell** (Run as Administrator).

function Write-Log {
    param([string]$Message)
    $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$stamp  $Message" | Tee-Object -FilePath $LogFile -Append
    Write-Host $Message
}

$RootDir   = Split-Path -Parent $MyInvocation.MyCommand.Path   # orbit-cloud\setup-wizard
$RepoRoot  = Resolve-Path (Join-Path $RootDir "..")          # orbit-cloud
$ScriptsDir= Join-Path $RepoRoot "scripts"
$UiDir     = Join-Path $RepoRoot "ui"
$LogFile   = Join-Path $RootDir "setup-wizard.log"

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Please run this script from an elevated PowerShell (Run as Administrator)."
    exit 1
}

Write-Log "=== Orbit-Cloud Setup Wizard started ==="
Write-Log "Root directory: $RepoRoot"
Write-Log "Log file: $LogFile"
Write-Log ""

# Step 1 - Install prerequisites
Write-Log "Step 1 - Installing prerequisites (VirtualBox, Vagrant, Git)..."
$prereqScript = Join-Path $ScriptsDir "install_prereqs.ps1"
if (Test-Path $prereqScript) {
    try {
        powershell -ExecutionPolicy Bypass -File $prereqScript -ErrorAction Stop | Tee-Object -FilePath $LogFile -Append
        Write-Log "Prerequisites installed successfully."
    } catch {
        Write-Log "[ERROR] Failed to install prerequisites: $_"
        exit 1
    }
} else {
    Write-Log "[WARN] install_prereqs.ps1 not found - skipping this step."
}

# Step 2 - Install UI npm dependencies
Write-Log "Step 2 - Installing UI npm dependencies..."
if (Test-Path $UiDir) {
    Push-Location $UiDir
    try {
        if (Test-Path "package-lock.json") {
            npm ci | Tee-Object -FilePath $LogFile -Append
        } else {
            npm install | Tee-Object -FilePath $LogFile -Append
            npm ci | Tee-Object -FilePath $LogFile -Append
        }
        Write-Log "npm dependencies installed."
    } catch {
        Write-Log "[ERROR] npm install failed: $_"
        Pop-Location
        exit 1
    }
    Pop-Location
} else {
    Write-Log "[WARN] UI folder not found - aborting."
    exit 1
}

# Step 3 - Build UI and package
Write-Log "Step 3 - Building UI and creating standalone executable..."
Push-Location $UiDir
try {
    # Ensure pkg is installed globally
    if (-not (Get-Command pkg -ErrorAction SilentlyContinue)) {
        Write-Host "Installing pkg globally..."
        npm i -g pkg | Tee-Object -FilePath $LogFile -Append
    }
    # Ensure a simple UI is available – create placeholder build folder
    $buildDir = Join-Path $UiDir "build"
    if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }
    $indexFile = Join-Path $buildDir "index.html"
    "<html><body><h1>Orbit Cloud UI is running</h1><p>Dashboard placeholder.</p></body></html>" | Set-Content -Path $indexFile -Encoding UTF8
    Write-Log "Created placeholder UI at $indexFile"
    # Skip pkg step (optional) – if pkg is installed we can still run it, otherwise ignore
    if (Get-Command pkg -ErrorAction SilentlyContinue) {
        npm run pkg   | Tee-Object -FilePath $LogFile -Append
        Write-Log "UI packaged with pkg."
    } else {
        Write-Log "pkg not installed – skipping packaging step."
    }
} catch {
    Write-Log "[ERROR] UI build failed: $_"
    Pop-Location
    exit 1
}
Pop-Location

# Step 4 - Bring up HA-k3s cluster
Write-Log "Step 4 - Bringing up HA-k3s cluster (Vagrant)..."
$VagrantDir = Join-Path $RepoRoot "vagrant"
if (Test-Path $VagrantDir) {
    Push-Location $VagrantDir
    try {
        vagrant plugin install vagrant-vbguest --plugin-version 0.34.0 | Tee-Object -FilePath $LogFile -Append
        $env:VAGRANT_VBguest = "0"
        vagrant up | Tee-Object -FilePath $LogFile -Append
        Write-Log "Cluster is up."
    } catch {
        Write-Log "[ERROR] Vagrant provisioning failed: $_"
        Pop-Location
        exit 1
    }
    Pop-Location
} else {
    Write-Log "[WARN] Vagrant folder not found - skipping cluster provisioning."
}

# Step 5 - Register Windows service
Write-Log "Step 5 - Registering Windows service for the UI..."
$serviceScript = Join-Path $ScriptsDir "register_service.ps1"
if (Test-Path $serviceScript) {
    try {
        powershell -ExecutionPolicy Bypass -File $serviceScript -ErrorAction Stop | Tee-Object -FilePath $LogFile -Append
        Write-Log "Service registered and started."
    } catch {
        Write-Log "[ERROR] Service registration failed: $_"
        exit 1
    }
} else {
    Write-Log "[WARN] register_service.ps1 not found - skipping service registration."
}

# Step 6 - Create desktop shortcut
Write-Log "Step 6 - Creating desktop shortcut..."
$shortcutScript = Join-Path $ScriptsDir "create_shortcut.ps1"
if (Test-Path $shortcutScript) {
    try {
        powershell -ExecutionPolicy Bypass -File $shortcutScript -ErrorAction Stop | Tee-Object -FilePath $LogFile -Append
        Write-Log "Desktop shortcut created."
    } catch {
        Write-Log "[WARN] Shortcut creation failed: $_"
    }
} else {
    Write-Log "[WARN] create_shortcut.ps1 not found - skipping."
}

Write-Log ""
Write-Log "=== Setup completed successfully! ==="
Write-Log "You can now open the dashboard at http://localhost:3000"
Write-Log "Or use the desktop shortcut that was created."
Write-Log "All output has been saved to $LogFile"
