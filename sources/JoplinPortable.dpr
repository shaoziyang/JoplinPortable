program JoplinPortable;

uses
  Forms,
  Unit1 in 'Unit1.pas' {FormMain};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.ShowMainForm:=false;
  Application.Run;
end.
