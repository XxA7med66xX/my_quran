#define MyAppName "My Quran"
#ifndef MyAppVersion
  #define MyAppVersion "1.0.0"
#endif
#define MyAppPublisher "DMouayad"
#define MyAppURL "https://github.com/DMouayad/my_quran"
#define MyAppExeName "my_quran.exe"
#define WorkingDir "D:\a\my_quran\my_quran"

; --- Detect platform at compile time ---
#define Arch1 GetEnv("PROCESSOR_ARCHITECTURE")
#define Arch2 GetEnv("PROCESSOR_ARCHITEW6432")

#if (Pos("ARM64", UpperCase(Arch1)) > 0) || (Pos("ARM64", UpperCase(Arch2)) > 0)
  #define BuildArch "arm64"
#else
  #define BuildArch "x64"
#endif

#define OutputArch StringChange(BuildArch, "x64", "x86_64")

[Setup]
AppId={{f4353203-40d1-4220-b710-b2b672191181}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
UninstallDisplayName={#MyAppName}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir={#WorkingDir}
OutputBaseFilename=MyQuran-{#MyAppVersion}-windows-{#OutputArch}-setup
SetupIconFile={#WorkingDir}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern
; SignTool=MySignTool (Used to sign the app)
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
; Optional task that creates a desktop shortcut if the user checks it during installation.
; Note: Flags: checkedonce means it's checked by default (on fresh installs).
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

; Optional task that creates a Start Menu shortcut.
Name: "startmenuicon"; Description: "Create a Start Menu shortcut"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
Source: "{#WorkingDir}\build\windows\{#BuildArch}\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WorkingDir}\build\windows\{#BuildArch}\runner\Release\*.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#WorkingDir}\build\windows\{#BuildArch}\runner\Release\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: startmenuicon
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
