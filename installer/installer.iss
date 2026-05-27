; Inno Setup script for Orbit-Cloud installer
; ---------------------------------------------------
[Setup]
AppName=Orbit-Cloud
AppVersion=1.0.0
DefaultDirName={pf}\OrbitCloud
DefaultGroupName=Orbit-Cloud
OutputBaseFilename=Orbit-Cloud-Setup
Compression=lzma
SolidCompression=yes
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
PrivilegesRequired=admin

[Files]
; Prerequisite installers will be downloaded at runtime, so only copy our repo and scripts
Source: "{#SourcePath}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs

[Run]
; Step 1 – Install prerequisites (VirtualBox, Vagrant, Git)
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File \"{app}\scripts\install_prereqs.ps1\""; Flags: runhidden waituntilterminated

; Step 2 – Clone repository (if not already present) – our files are already in {app}
; Step 3 – Install vagrant‑vbguest plugin and bring up the cluster
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File \"{app}\scripts\post_install.ps1\""; Flags: runhidden waituntilterminated

; Step 4 – Register Windows service for the UI
Filename: "powershell.exe"; Parameters: "-ExecutionPolicy Bypass -File \"{app}\scripts\register_service.ps1\""; Flags: runhidden waituntilterminated

; Step 5 – Create desktop shortcut to UI
Filename: "{app}\scripts\create_shortcut.ps1"; Parameters: ""; Flags: runhidden

[Icons]
Name: "{commondesktop}\Orbit Cloud UI"; Filename: "{app}\ui\orbit-cloud-ui.exe"; WorkingDir: "{app}\ui"; IconFilename: "{app}\ui\orbit-cloud-ui.exe"
