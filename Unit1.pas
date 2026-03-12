unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON,
  uBaseGenerator, uWordleGenerator, uQueensGenerator, uNerdleGenerator,
  uZipGenerator, uHexleGenerator, uWorldleGenerator;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Label1: TLabel;
    Edit1: TEdit;
    Button1: TButton;
  private
    { Private declarations }
    FWordleGen: TOctailyWordleGenerator;
    FNerdleGen: TOctailyNerdleGenerator;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

end.
