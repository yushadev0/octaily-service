unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON,
  uBaseGenerator, uWordleGenerator, uQueensGenerator;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    FWordleGen: TOctailyWordleGenerator;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  QueensGen: TOctailyQueensGenerator;
  PuzzleJSON: TJSONObject;
begin
  Memo1.Clear;
  // 8x8 boyutunda bir Queens bulmacası oluşturalım
  QueensGen := TOctailyQueensGenerator.Create('queens_daily', 8);
  try
    // 1. Bulmacayı üret (Backtracking + Region Growth çalışır)
    QueensGen.GenerateDailyPuzzle;

    // 2. Üretilen bulmacayı JSON olarak al
    PuzzleJSON := QueensGen.GetDailyPuzzleJSON;
    try
      Memo1.Lines.Add('--- QUEENS GÜNLÜK BULMACA ---');
      Memo1.Lines.Add(PuzzleJSON.Format(2));
    finally
      PuzzleJSON.Free;
    end;
  finally
    QueensGen.Free;
  end;
end;

end.
