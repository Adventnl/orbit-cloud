param(
    [string]$ServiceName = "OrbitCloudWeb",
    [string]$ExePath = "${env:APPDIR}\ui\orbit-cloud-ui.exe",
    [string]$DisplayName = "Orbit Cloud UI Service",
    [string]$Description = "Runs the Orbit‑Cloud UI as a background service"
)

# Resolve full path (fallback to relative path if APPDIR not set)
if (-not (Test-Path $ExePath)) {
    $ExePath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\ui\orbit-cloud-ui.exe"
    $ExePath = Resolve-Path $ExePath
}

# Stop and delete existing service if present
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    Write-Host "Stopping existing service $ServiceName..."
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Write-Host "Removing existing service $ServiceName..."
    sc.exe delete $ServiceName | Out-Null
}

# Create new service
Write-Host "Creating Windows service $ServiceName..."
sc.exe create $ServiceName binPath= "`"$ExePath`"" start= auto DisplayName= "`$DisplayName`" | Out-Null
sc.exe description $ServiceName "$Description" | Out-Null

# Start service
Write-Host "Starting service $ServiceName..."
Start-Service -Name $ServiceName

Write-Host "Service $ServiceName installed and started successfully."
