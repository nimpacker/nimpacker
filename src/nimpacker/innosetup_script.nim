import std/[os, strformat, strutils]
import ./packageinfo
import parseini

proc getInnoSetupScript*(pkgInfo: PackageInfo, dir: string, icoPath: string, metaInfo: MetaInfo): string =
  let productName = metaInfo.productName
  let name = if productName.len > 0: productName else: pkgInfo.name
  let defines = fmt"""
    #define MyAppName "{name}"
    #define MyAppVersion "{pkgInfo.version}"
    #define MyAppPublisher "{pkgInfo.author}"
    #define MyAppURL "{metaInfo.homepage}"
    #define MyAppExeName "{pkgInfo.name}.exe"
    """

  var dict = newConfig()
  dict.setSectionKey("Setup", "AppId", "{{" & metaInfo.appId & "}", false)
  dict.setSectionKey("Setup", "OutputDir", getCurrentDir() / "dist", false)
  dict.setSectionKey("Setup", "AppName", "{#MyAppName}", false)
  dict.setSectionKey("Setup", "AppVersion", "{#MyAppVersion}", false)
  dict.setSectionKey("Setup", ";AppVerName", "{#MyAppName} {#MyAppVersion}", false)
  dict.setSectionKey("Setup", "AppPublisher", "{#MyAppPublisher}", false)
  dict.setSectionKey("Setup", "AppPublisherURL", "{#MyAppURL}", false)
  dict.setSectionKey("Setup", "AppSupportURL", "{#MyAppURL}", false)
  dict.setSectionKey("Setup", "AppUpdatesURL", "{#MyAppURL}", false)
  dict.setSectionKey("Setup", "DefaultDirName", "{autopf}\\{#MyAppName}", false)
  dict.setSectionKey("Setup", "DisableProgramGroupPage", "yes", false)
  dict.setSectionKey("Setup", ";PrivilegesRequired", "lowest", false)
  dict.setSectionKey("Setup", "OutputBaseFilename", fmt"{pkgInfo.name}-setup", false)
  dict.setSectionKey("Setup", "SetupIconFile", icoPath, false)
  dict.setSectionKey("Setup", "Compression", "lzma", false)
  dict.setSectionKey("Setup", "SolidCompression", "yes", false)
  dict.setSectionKey("Setup", "WizardStyle", "modern", false)
  let setup = $dict

  let others = """
    [Languages]
    Name: "english"; MessagesFile: "compiler:Default.isl"

    [Tasks]
    Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

    [Files]
    Source: "$1\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion
    ; NOTE: Don't use "Flags: ignoreversion" on any shared system files
    [Icons]
    Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
    Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

    [Run]
    Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

    """ % [dir]
  result = defines.unindent & setup & others.unindent

