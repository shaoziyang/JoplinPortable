unit Unit1;

interface

uses
  Windows,
  ShellAPI,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  ExtCtrls,
  Buttons,
  IniFiles,
  Grids,
  Outline,
  DirOutln,
  FileCtrl;

type
  TfrmMain = class(TForm)
    pnl1: TPanel;
    grp1: TGroupBox;
    rb1: TRadioButton;
    rb2: TRadioButton;
    img1: TImage;
    img2: TImage;
    mmo1: TMemo;
    pnl2: TPanel;
    pnl3: TPanel;
    edt1: TEdit;
    btn2: TSpeedButton;
    fllst1: TFileListBox;
    lst1: TListBox;
    pnl4: TPanel;
    btn1: TSpeedButton;
    btn3: TSpeedButton;
    pnl5: TPanel;
    btn4: TSpeedButton;
    btn5: TSpeedButton;
    lbl1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure rb1Click(Sender: TObject);
    procedure btn2Click(Sender: TObject);
    procedure lst1Click(Sender: TObject);
    procedure btn3Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btn4Click(Sender: TObject);
    procedure btn5Click(Sender: TObject);
  private
    { Private declarations }
    procedure setLang(lang: string);
    procedure updateDir;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;
  ini: TIniFile;
  path, lang: string;
  s: string;
  F: TextFile;
  note: string;

implementation

{$R *.dfm}

procedure TfrmMain.btn1Click(Sender: TObject);
begin
  btn3Click(Sender);
  ShellExecute(0, 'open', PChar(path + 'JoplinPortable.cmd'), '', PChar(path), SW_HIDE);
end;

procedure TfrmMain.btn2Click(Sender: TObject);
begin
  s := Trim(edt1.Text);
  if lst1.Items.IndexOf(s) = -1 then
  begin
    CreateDir(path + 'Notes\' + s);
    updateDir;
  end
  else
    Beep;
end;

procedure TfrmMain.btn3Click(Sender: TObject);
begin
  try
    s := lst1.Items[lst1.Tag];
    AssignFile(F, path + 'JoplinPortable.cmd');
    Rewrite(F);
    write(F, '@start "" "%~dp0\App\Joplin\Joplin.exe" --profile "%~dp0\Notes\' + s + '"');

    note := s;
    ini.WriteString('option', 'note', note);
    ini.UpdateFile;
  finally
    CloseFile(F);
  end;
end;

procedure TfrmMain.btn4Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, nil, 'https://gitee.com/shaoziyang/joplinportable', nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmMain.btn5Click(Sender: TObject);
begin
  ShellExecute(Application.Handle, nil, 'https://github.com/shaoziyang/JoplinPortable', nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  ID: LangID;
begin
  edt1.Text := '';

  path := ExtractFilePath(Application.ExeName);
  if not DirectoryExists(path + 'Notes') then
    CreateDir(path + 'Notes');

  ini := TIniFile.Create(ChangeFileExt(Application.ExeName, '.ini'));

  Left := ini.ReadInteger('option', 'left', 80);
  Top := ini.ReadInteger('option', 'top', 80);
  Width := ini.ReadInteger('option', 'width', 400);
  Height := ini.ReadInteger('option', 'height', 360);
  note := ini.ReadString('option', 'note', '');

  lang := ini.ReadString('option', 'lang', '');
  if lang = '' then
  begin
    ID := GetSystemDefaultLangID;
    if ID = 2052 then
      lang := 'Chinese'
    else
      lang := 'English';
    ini.WriteString('option', 'lang', lang);
  end;

  if lang = 'Chinese' then
    rb2.Checked := True
  else
    rb1.Checked := True;
  setLang(lang);

  updateDir;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  try
    ini.WriteInteger('option', 'left', Left);
    ini.WriteInteger('option', 'top', Top);
    ini.WriteInteger('option', 'width', Width);
    ini.WriteInteger('option', 'height', Height);
    ini.UpdateFile;
    ini.Free;
  except
    Application.Terminate;
  end;
end;

procedure TfrmMain.lst1Click(Sender: TObject);
var
  i: Integer;
begin
  for I := 0 to lst1.Count - 1 do
    if lst1.Selected[i] then
    begin
      lst1.Tag := i;
      Break;
    end;

  btn1.Enabled := lst1.Tag <> -1;
  btn3.Enabled := btn1.Enabled;
end;

procedure TfrmMain.rb1Click(Sender: TObject);
begin
  if rb1.Checked then
  begin
    setLang('English');
    ini.WriteString('option', 'lang', 'English');
  end
  else
  begin
    setLang('Chinese');
    ini.WriteString('option', 'lang', 'Chinese');
  end;
end;

procedure TfrmMain.setLang(lang: string);
begin
  if lang = 'Chinese' then
  begin
    Caption := 'Joplin 笔记切换工具';
    grp1.Caption := '语言';
    btn1.Caption := '保存并运行';
    btn2.Caption := '添加';
    btn3.Caption := '保存';
    lbl1.Caption := '笔记本';
    mmo1.Text := '“Joplin 笔记切换工具”是 Joplin 便携版带有的一个小工具，可以帮助使用者切换不同的笔记，每个笔记保存在 "Notes" 文件夹下的不同目录中。' + #13#10#13#10 + '#注意#' + #13#10 + '不同的笔记需要设置不同的同步方式，否则会造成冲突！';
  end
  else
  begin
    Caption := 'Joplin Notebook Switcher';
    grp1.Caption := 'Language';
    btn1.Caption := 'Save and Run';
    btn2.Caption := 'Add';
    btn3.Caption := 'Save';
    lbl1.Caption := 'Notebook';
    mmo1.Text := '"Joplin Notebook Switcher" is a part of Joplin portable, it can help users switch between different notes, each note is saved in a different directory under the "notes" folder.' + #13#10#13#10 + '#Notice#' + #13#10 + 'Please note that different notes need to set different synchronization methods, otherwise it will cause conflict!';
  end;
end;

procedure TfrmMain.updateDir;
var
  i: Integer;
begin
  lst1.Items.Clear;
  lst1.Tag := -1;

  fllst1.ApplyFilePath(path + 'Notes');
  fllst1.Update;

  for I := 0 to fllst1.Items.Count - 1 do
  begin
    s := fllst1.Items[i];
    if (s = '[.]') or (s = '[..]') then
      Continue;

    if Length(s) > 2 then
    begin
      s := Copy(s, 2, Length(s) - 2);
      if s <> '' then
        lst1.Items.Add(s);
    end;
  end;

  if note <> '' then
  begin
    i := lst1.Items.IndexOf(note);
    if i <> -1 then
    begin
      lst1.Selected[i] := True;
    end;
  end;
end;

end.

