[Setup]
AppName=Claude RTL
AppVersion=1.0.0
AppPublisher=GRW Lab
DefaultDirName={autopf}\Claude RTL
DefaultGroupName=Claude RTL
OutputBaseFilename=ClaudeRTL-Setup-1.0.0
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
SetupIconFile=..\Resources\AppIcon.ico

[Files]
Source: "..\publish\ClaudeRTL.exe"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Claude RTL"; Filename: "{app}\ClaudeRTL.exe"
Name: "{userstartup}\Claude RTL"; Filename: "{app}\ClaudeRTL.exe"; Tasks: startupicon

[Tasks]
Name: "startupicon"; Description: "تشغيل Claude RTL عند بدء النظام"; GroupDescription: "خيارات:"

[Run]
Filename: "{app}\ClaudeRTL.exe"; Description: "تشغيل Claude RTL الآن"; Flags: nowait postinstall skipifsilent
