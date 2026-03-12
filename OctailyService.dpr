program OctailyService;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  uBaseGenerator in 'generators\uBaseGenerator.pas',
  uWordleGenerator in 'generators\uWordleGenerator.pas',
  uQueensGenerator in 'generators\uQueensGenerator.pas',
  uNerdleGenerator in 'uNerdleGenerator.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
