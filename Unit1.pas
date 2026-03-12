unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.JSON,
  uBaseGenerator, uWordleGenerator, uQueensGenerator, uNerdleGenerator;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Button1: TButton;
    Label1: TLabel;
    Edit1: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
  GuessJSON: TJSONObject;
begin
  Memo1.Clear;

  // Edit1'e yazdığın tahmini gönder (Örn: 12+35=47)
  GuessJSON := FNerdleGen.CheckGuess(Edit1.Text);
  try
    Memo1.Lines.Add('--- NERDLE TAHMİN SONUCU ---');
    Memo1.Lines.Add(GuessJSON.Format(2));
  finally
    GuessJSON.Free;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
// Nerdle jeneratörünü başlat (Parametre sadece oyun adı)
  FNerdleGen := TOctailyNerdleGenerator.Create('nerdle_daily');

  // Günlük denklemi üret
  FNerdleGen.GenerateDailyPuzzle;

  // Test için gizli denklemi label'da görelim
  Label1.Caption := 'Gizli Denklem: ' + FNerdleGen.DailyEquation;
end;

end.
