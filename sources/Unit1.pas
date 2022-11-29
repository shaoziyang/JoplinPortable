unit Unit1;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  ImgList,
  ExtCtrls,
  shellapi,
  IniFiles,
  TLHelp32,
  Menus,
  StdCtrls,
  ComCtrls;

const
  GITHUB_URL = 'https://github.com/shaoziyang/JoplinPortable';


type
  TFormMain = class(TForm)
    tray: TTrayIcon;
    ilTray: TImageList;
    pmTray: TPopupMenu;
    N1: TMenuItem;
    pmExit: TMenuItem;
    pmJoplinPortable: TMenuItem;
    pmAdd: TMenuItem;
    N3: TMenuItem;
    pmnote: TMenuItem;
    N2: TMenuItem;
    mmoNotes: TMemo;
    tmrWDG: TTimer;
    pbBar: TProgressBar;
    procedure pmExitClick(Sender: TObject);
    procedure pmAddClick(Sender: TObject);
    procedure pmnoteClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure tmrWDGTimer(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure trayClick(Sender: TObject);
    procedure pmJoplinPortableClick(Sender: TObject);
  private
    { Private declarations }
    WDGen: Boolean;
    curNote: string;

    joplin_app, joplin_notes_path: string;
    app_path: string;
    ini: TIniFile;

    procedure FindNotes;
    procedure addNote(name: string);
  public
    { Public declarations }
    function KillTask(ExeFileName: string): Integer;
    procedure CloseJoplin;
    procedure FrontJoplin;
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

function TFormMain.KillTask(ExeFileName: string): Integer;
const
  PROCESS_TERMINATE = $0001;
var
  ContinueLoop: BOOL;
  FSnapshotHandle: THandle;
  FProcessEntry32: TProcessEntry32;
begin
  Result := 0;
  FSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  FProcessEntry32.dwSize := SizeOf(FProcessEntry32);
  ContinueLoop := Process32First(FSnapshotHandle, FProcessEntry32);

  while Integer(ContinueLoop) <> 0 do
  begin
    if ((UpperCase(ExtractFileName(FProcessEntry32.szExeFile)) =
      UpperCase(ExeFileName)) or (UpperCase(FProcessEntry32.szExeFile) =
      UpperCase(ExeFileName))) then
      Result := Integer(TerminateProcess(
        OpenProcess(PROCESS_TERMINATE,
        BOOL(0),
        FProcessEntry32.th32ProcessID),
        0));
    ContinueLoop := Process32Next(FSnapshotHandle, FProcessEntry32);
  end;
  CloseHandle(FSnapshotHandle);
end;

procedure TFormMain.addNote(name: string);
var
  pmi: TMenuItem;
  n: Integer;
begin
  n := pmTray.Items.IndexOf(pmAdd);
  pmi := TMenuItem.Create(pmTray);
  pmi.Caption := '[' + name + ']';
  pmi.Hint := name;
  pmi.AutoCheck := True;
  pmi.RadioItem := True;
  pmi.Tag := n;
  pmi.OnClick := pmnoteClick;
  pmTray.Items.Insert(n - 2, pmi);
  mmoNotes.Lines.Append(name);
end;

procedure TFormMain.CloseJoplin;
var
  joplin: THandle;
  n: Integer;
begin
  joplin := FindWindow(nil, 'Joplin');
  if joplin <> 0 then
  begin
    KillTask('Joplin.exe');
    n := 100;
    while n > 0 do
    begin
      n := n - 1;
      Application.ProcessMessages;
      Sleep(10);
      joplin := FindWindow(nil, 'Joplin');
      if joplin = 0 then
        n := 0;
    end;
  end;
end;

// search dir

procedure TFormMain.FindNotes;
var
  sr: TSearchRec;
begin
  if FindFirst(joplin_notes_path + '*', faAnyFile, sr) = 0 then
    repeat
      if (sr.attr = faDirectory) and (sr.Name <> '.') and (sr.Name <> '..') then
      begin
        addNote(sr.Name);
      end;
    until FindNext(sr) <> 0;
  FindClose(sr);
  if pmTray.Items.IndexOf(pmAdd) = 3 then
  begin
    addNote('Default');
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
begin
  pbBar.Position:=0;
  FormMain.AutoSize:=True;
  app_path := ExtractFilePath(Application.ExeName);
  joplin_app := app_path + 'App\Joplin\Joplin.exe';
  joplin_notes_path := app_path + 'Notes\';
  if not DirectoryExists(joplin_notes_path) then
    CreateDir(joplin_notes_path);


  // load note name
  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));
  curNote := ini.ReadString('cfg', 'note', 'Default');

  mmoNotes.Lines.Clear;

  FindNotes;
  Tag := mmoNotes.Lines.IndexOf(curNote);
  if Tag = -1 then
  begin
    if mmoNotes.Lines.Count > 0 then
    begin
      pmnoteClick(pmTray.Items[2]);
    end
    else
    begin
      addNote(curNote);
      pmnoteClick(pmTray.Items[pmTray.Items.Count - 6]);
    end;
  end
  else
  begin
    pmnoteClick(pmTray.Items[Tag + 2]);
  end;

end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  try
    try
      // save current note name
      ini.WriteString('cfg', 'note', curNote);

      ini.UpdateFile;
    except

    end;
  finally
    ini.Free;
  end;
end;

// bring joplin to front

procedure TFormMain.FrontJoplin;
var
  joplin: THandle;
begin
  joplin := FindWindow(nil, 'Joplin');
  if joplin <> 0 then
  begin
    ShowWindow(joplin, SW_RESTORE);
    SetForegroundWindow(joplin);
  end;

end;

// note click event, switch notes

procedure TFormMain.pmnoteClick(Sender: TObject);
var
  s: string;
  n: Integer;
begin
  if (curNote = TMenuItem(Sender).Hint) and (FindWindow(nil, 'Joplin') <> 0) then
  begin
    FrontJoplin;
  end
  else
  begin
    WDGen := False;
    CloseJoplin;
    Application.ShowMainForm := True;
    FormMain.Show;
    FormMain.BringToFront;

    TMenuItem(Sender).Checked := True;
    curNote := TMenuItem(Sender).Hint;
    s := joplin_notes_path + curNote;
    ShellExecute(Handle, '', PChar(joplin_app), PChar('--profile "' + s + '"'), '', SW_SHOW);
    n := pmTray.Items.IndexOf(TMenuItem(Sender)) - 2;

  // set tray icon
    if n > 9 then n := 9;
    tray.IconIndex := n;

    pbBar.Max:=1000;
    n := pbBar.Max;
    while n > 0 do
    begin
      pbBar.Position := pbBar.Max - n;
      n := n - 1;
      Application.ProcessMessages;
      Sleep(10);
      if FindWindow(nil, 'Joplin') <> 0 then
      begin
        if n > pbBar.Max div 3 then
          n := pbBar.Max div 3;
      end;
    end;
    FormMain.Hide;
    Application.ShowMainForm := False;
    WDGen := True;
  end;
end;

procedure TFormMain.pmJoplinPortableClick(Sender: TObject);
begin
   ShellExecute(Handle, '',GITHUB_URL,  '', '', SW_SHOW);
end;

procedure TFormMain.tmrWDGTimer(Sender: TObject);
begin
  if WDGen then
  begin
    // Monitoring joplin, if joplin exit, close JoplinPortable itself
    // In order to prevent accidental detection errors,
    // continuously monitor for 10 times
    if FindWindow(nil, 'Joplin') = 0 then
    begin
      tmrWDG.Tag := tmrWDG.Tag + 1;
      if tmrWDG.Tag > 10 then
        Close;
    end
    else
    begin
      tmrWDG.Tag := 0;
    end;
  end;

end;

procedure TFormMain.trayClick(Sender: TObject);
begin
  FrontJoplin;
end;

// add new note

procedure TFormMain.pmAddClick(Sender: TObject);
var
  s: string;
begin
  s := InputBox('Pleasse input note name', 'Note name:', '');

  if s = '' then
    Exit;

  if mmoNotes.Lines.IndexOf(s) = -1 then
  begin
    addNote(s);
//    pmnoteClick(pmTray.Items[pmTray.Items.Count - 6]);
  end
  else
  begin
    MessageBox(Handle, PChar('[' + s + '] is already exist!'), 'Error', MB_OK + MB_ICONSTOP);
  end;

end;

procedure TFormMain.pmExitClick(Sender: TObject);
begin
  // close Joplin, then WDG close all
  CloseJoplin;
end;

end.

