unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON,
  uBaseGenerator, uWordleGenerator, uQueensGenerator, uNerdleGenerator,
  uZipGenerator, uHexleGenerator;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Label1: TLabel;
    Edit1: TEdit;
    procedure Button1Click(Sender: TObject);
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

procedure TForm1.Button1Click(Sender: TObject);
var
  HexGen: TOctailyHexleGenerator;
  ResultJSON: TJSONObject;
  I: Integer;
begin
  Memo1.Clear;
  HexGen := TOctailyHexleGenerator.Create('hexle_daily');
  try
    HexGen.GenerateDailyPuzzle;
    Label1.Caption := 'Hedef Renk: #' + HexGen.DailyHex;

    // Örnek tahmin: "FFFFFF" (Beyaz)
    ResultJSON := HexGen.CheckGuess(Edit1.Text);
    try
      Memo1.Lines.Add(ResultJSON.Format(2));
    finally
      ResultJSON.Free;
    end;
  finally
    HexGen.Free;
  end;
end;

end.
