[Setup]
AppName=Claude RTL
AppVersion=1.1.2
AppPublisher=GRW Lab
DefaultDirName={autopf}\Claude RTL
DefaultGroupName=Claude RTL
OutputBaseFilename=ClaudeRTL-Setup-1.1.2
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
SetupIconFile=..\Resources\AppIcon.ico

[Files]
Source: "..\publish\ClaudeRTL.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\publish\WinSparkle.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\publish\Resources\*"; DestDir: "{app}\Resources"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Claude RTL"; Filename: "{app}\ClaudeRTL.exe"
Name: "{userstartup}\Claude RTL"; Filename: "{app}\ClaudeRTL.exe"; Parameters: "--tray-only"; Tasks: startupicon

[Tasks]
Name: "startupicon"; Description: "تشغيل Claude RTL عند بدء النظام"; GroupDescription: "خيارات:"

[Run]
Filename: "{app}\ClaudeRTL.exe"; Description: "تشغيل Claude RTL الآن"; Flags: nowait postinstall skipifsilent
