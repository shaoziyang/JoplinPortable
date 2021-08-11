program JoplinPortable;

uses
  Windows,
  ShellAPI,
  IniFiles,
  SysUtils;

{$R *.res}

var
  path: string;
  AppName: string;
  DataPath: string;
  ini: TIniFile;

begin
  path := ExtractFilePath(ParamStr(0));

  if FileExists(path + 'JoplinPortable.cmd') then
  begin
    ShellExecute(0, 'open', PChar(path + 'JoplinPortable.cmd'), '', PChar(path), SW_HIDE);
  end
  else
  begin
    AppName := path + 'App\Joplin\Joplin.exe';
    ini := TIniFile.Create(path + 'JoplinSwitch.ini');
    DataPath := ini.ReadString('option', 'note', '');
    ini.Free;

    if DataPath = '' then
      DataPath := path + 'Notes\default'
    else
      DataPath := path + 'Notes\' + DataPath;

    ShellExecute(0, 'open', PChar(AppName), PChar('--profile ' + DataPath), '', SW_SHOW);
  end;
end.

