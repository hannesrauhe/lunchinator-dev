; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

[Setup]
AppName=Lunchinator
AppVersion=0.2
PrivilegesRequired=lowest
AppId={{503677A7-7464-4740-A00D-213B0BB3B612}
RestartIfNeededByRun=False
DefaultDirName={userpf}\Lunchinator
DisableWelcomePage=True
DisableReadyPage=True
OutputDir=.\win
OutputBaseFilename=setup_lunchinator
AllowNoIcons=yes
DefaultGroupName=Lunchinator

[InstallDelete]
Type: filesandordirs; Name: "{app}\plugins"
Type: filesandordirs; Name: "{app}\lunchinator"

[Files]
Source: "lunchinator\dist\lunchinator.exe"; DestDir: "{app}"
Source: "bin\*"; DestDir: "{app}\bin"
Source: "lunchinator\*"; DestDir: "{app}\"; Flags: recursesubdirs; Excludes: "*.pyc,dist"

[Tasks]
Name: startup; Description: "Automatically start on login"; GroupDescription: "{cm:AdditionalIcons}"

[Icons]
Name: "{group}\Lunchinator"; Filename: "{app}\lunchinator.exe"; Parameters: "--show-window"; WorkingDir: "{app}"
Name: "{group}\Lunchinator (Start Hidden)"; Filename: "{app}\lunchinator.exe"; WorkingDir: "{app}"
Name: "{group}\Lunchinator (Python)"; Filename: "pythonw"; Parameters: "{app}\start_lunchinator.py"; WorkingDir: "{app}"
Name: "{group}\Lunchinator (Python Command Line)"; Filename: "python"; Parameters: "{app}\start_lunchinator.py --cli"; WorkingDir: "{app}"
Name: "{group}\Uninstall Lunchinator"; Filename: "{uninstallexe}"
Name: "{userstartup}\Lunchinator"; Filename: "{app}\lunchinator.exe"; WorkingDir: "{app}"; Tasks: startup

[Dirs]
Name: "{app}\plugins"

[Run]
Filename: "{app}\lunchinator.exe"; WorkingDir: "{app}"; Parameters: "--show-window"; Flags: nowait postinstall

