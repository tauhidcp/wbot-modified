{
 _    _  _         _____
| |  | || |       |_   _|   /|
| |  | || |___  ___ | |    / |__
| |/\| ||  _  |/ _ \| |   /_   /
| /  \ || (_) | (_) | |     | /
|__/\__||_____|\___/|_|     |/

}
unit WBot_Config;

{$i wbot.inc}

interface

uses
  SysUtils, LResources, IniFiles,
  // CEF
  uCEFApplication,
  // WBot
  WBot_Const;
                           
function CreateGlobalCEFApp: boolean;
procedure DestroyGlobalCEFApp;

implementation

var
  LocalIni: TIniFile = nil;

procedure CreateLocalIni;
begin
  LocalIni := TIniFile.Create(WBOT_INI);
end;

procedure DestroyLocalIni;
begin
  FreeAndNil(LocalIni);
end;

function CreateGlobalCEFApp: boolean;
begin
  {$IfDef wbot_debug}
  WriteLn('CreateGlobalCEFApp');
  {$EndIf}
  if (not(Assigned(GlobalCEFApp))) then
  begin
    GlobalCEFApp := TCefApplication.Create;
    GlobalCEFApp.FrameworkDirPath :=
      UnicodeString(LocalIni.ReadString('Paths', 'FrameWork', 'cef'));
    GlobalCEFApp.ResourcesDirPath :=
      UnicodeString(LocalIni.ReadString('Paths', 'Resources', 'cef'));
    GlobalCEFApp.LocalesDirPath :=
      UnicodeString(LocalIni.ReadString('Paths', 'Locales', 'cef'+ PathDelim + 'locales'));
    GlobalCEFApp.Cache :=
      UnicodeString(LocalIni.ReadString('Paths', 'Cache', 'tmp' + PathDelim + 'cache'));
  end;
  Result := GlobalCEFApp.StartMainProcess;
end;

procedure DestroyGlobalCEFApp;
begin
  if (string(GlobalCEFApp.FrameworkDirPath) <> EmptyStr) then
  begin
    LocalIni.WriteString('Paths', 'FrameWork',
      string(GlobalCEFApp.FrameworkDirPath));
  end
  else
  begin    
    LocalIni.WriteString('Paths', 'FrameWork',
     ExtractFilePath(ParamStr(0)) + 'cef')
  end;
  if (string(GlobalCEFApp.ResourcesDirPath) <> EmptyStr) then
  begin
    LocalIni.WriteString('Paths', 'Resources',
      string(GlobalCEFApp.ResourcesDirPath));
  end
  else
  begin                                      
    LocalIni.WriteString('Paths', 'Resources',
     ExtractFilePath(ParamStr(0)) + 'cef')
  end;
  if (string(GlobalCEFApp.LocalesDirPath) <> EmptyStr) then
  begin
    LocalIni.WriteString('Paths', 'Locales',
      string(GlobalCEFApp.LocalesDirPath));
  end
  else
  begin                                     
    LocalIni.WriteString('Paths', 'Locales',
     ExtractFilePath(ParamStr(0)) + 'cef'+ PathDelim + 'locales')
  end;
  LocalIni.WriteString('Paths', 'Cache', string(GlobalCEFApp.Cache));
//  LocalIni.WriteString('Paths', 'UserData', string(GlobalCEFApp.UserDataPath));
  FreeAndNil(GlobalCEFApp);   
  {$IfDef wbot_debug}
  WriteLn('DestroyGlobalCEFApp');
  {$EndIf}
end;

initialization
  CreateLocalIni;

finalization
  DestroyLocalIni;

end.
