param([string]$InstallDir = "C:\Program Files")
# URLs for the latest installers (as of 2026) – adjust if newer versions needed
$virtualBoxUrl = "https://download.virtualbox.org/virtualbox/7.0.30/VirtualBox-7.0.30-156879-Win.exe"
$vagrantUrl    = "https://releases.hashicorp.com/vagrant/2.4.1/vagrant_2.4.1_x86_64.msi"
$gitUrl        = "https://github.com/git-for-windows/git/releases/download/v2.45.0.windows.1/Git-2.45.0-64-bit.exe"

function Download-And-Install($url, $args) {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "Elevating script to Administrator..."
        $installArgs = "-NoProfile -ExecutionPolicy Bypass -File \"$PSCommandPath\""
        Start-Process -FilePath powershell -Verb RunAs -ArgumentList $installArgs
        exit
    }
    $file = "$env:TEMP\$(Split-Path $url -Leaf)"
    Write-Host "Downloading $url ..."
    Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing
    Write-Host "Installing $file ..."
    & $file $args /quiet /norestart
    if ($LASTEXITCODE -ne 0) {
        Throw "Installation failed for $url (exit=$LASTEXITCODE)"
    }
    Remove-Item $file -Force
}

# Install VirtualBox (silent, no reboot)
Download-And-Install $virtualBoxUrl "/S"
# Install Vagrant (MSI silent)
Download-And-Install $vagrantUrl "/qn"
# Install Git (silent)
Download-And-Install $gitUrl "/VERYSILENT /NORESTART"

Write-Host "All prerequisites installed successfully."
